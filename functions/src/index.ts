import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import OpenAI from "openai";
import * as path from "path";
import * as os from "os";
import * as fs from "fs";

admin.initializeApp();

const OPENAI_KEY = defineSecret("OPENAI_API_KEY");

export const indexMaterial = onCall(
  {
    region: "northamerica-northeast2",
    secrets: [OPENAI_KEY],
    timeoutSeconds: 300,
  },
  async (req) => {
    const { userId, courseId, courseName, materialId, storagePath } = req.data;

    // Validate fields
    if (!userId || !courseId || !materialId || !storagePath) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required fields: userId, courseId, materialId, storagePath."
      );
    }

    const openai = new OpenAI({ apiKey: OPENAI_KEY.value() });

    const db = admin.firestore();
    const courseRef = db
      .collection("users")
      .doc(userId)
      .collection("courses")
      .doc(courseId);

    const materialRef = courseRef.collection("materials").doc(materialId);

    // Mark the material as indexing (UI feedback)
    await materialRef.update({
      status: "indexing",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const tempLocalFile = path.join(os.tmpdir(), `${materialId}.pdf`);

    try {
      console.log("========== INDEX MATERIAL START ==========");
      console.log("[Input]", req.data);

      // Load course
      console.log("[Firestore] Fetching course document...");
      const courseSnap = await courseRef.get();
      const course = courseSnap.data();
      let vectorStoreId = course?.vectorStoreId ?? null;

      // 1️⃣ If no vector store exists → create one
      if (!vectorStoreId) {
        console.log("[OpenAI] No vector store found. Creating...");

        const store = await openai.vectorStores.create({
          name: `${courseName ?? "course"}_vector_store`,
        });

        vectorStoreId = store.id;

        console.log("[OpenAI] Vector store created:", vectorStoreId);

        await courseRef.update({
          vectorStoreId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // 2️⃣ Download PDF from Storage → temp file
      console.log("[Firebase Storage] Downloading file:", storagePath);
      await admin.storage().bucket().file(storagePath).download({
        destination: tempLocalFile,
      });
      console.log("[Temp] File downloaded to:", tempLocalFile);

      // 3️⃣ Upload file to OpenAI Files API
      console.log("[OpenAI] Uploading file to Files API...");
      const fileUpload = await openai.files.create({
        file: fs.createReadStream(tempLocalFile),
        purpose: "assistants",
      });

      const fileId = fileUpload.id;
      console.log("[OpenAI] File uploaded. File ID:", fileId);

      // 4️⃣ Add file to vector store
      console.log("[OpenAI] Adding file to Vector Store:", vectorStoreId);
      await openai.vectorStores.files.create(vectorStoreId, {
        file_id: fileId,
      });

      console.log("[OpenAI] File added to Vector Store successfully!");

      // 5️⃣ Update material document
      console.log("[Firestore] Updating material...");
      await materialRef.update({
        openAiFileId: fileId,
        status: "indexed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("========== INDEX MATERIAL COMPLETE ==========");

      return {
        vectorStoreId,
        fileId,
        message: "Material successfully indexed.",
      };
    } catch (error: any) {
      console.error("========== INDEX MATERIAL ERROR ==========");
      console.error("[Error Message]:", error.message);
      console.error("[Error Raw]:", error);

      // If OpenAI returned a request ID, log it (GOLD for debugging)
      const requestId =
        error?.response?.headers?.["x-request-id"] ??
        error?.response?.headers?.get?.("x-request-id");
      if (requestId) console.error("[OpenAI Request ID]:", requestId);

      // Update Firestore status
      await materialRef.update({
        status: "error",
        lastError: error?.message ?? "Unknown indexing error",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      throw new HttpsError(
        "internal",
        `Indexing failed: ${error.message ?? "Unknown error"}`
      );
    } finally {
      // Cleanup temp file
      if (fs.existsSync(tempLocalFile)) {
        try {
          fs.unlinkSync(tempLocalFile);
          console.log("[Temp] Cleaned up temp file.");
        } catch (cleanupErr) {
          console.error("[Temp] Failed to remove temp file:", cleanupErr);
        }
      }
    }
  }
);

export const deleteMaterial = onCall(
  {
    region: "northamerica-northeast2",
    secrets: [OPENAI_KEY],
    timeoutSeconds: 120,
  },
  async (req) => {
    const { userId, courseId, materialId } = req.data;

    if (!userId || !courseId || !materialId) {
      throw new HttpsError(
        "invalid-argument",
        "Missing userId, courseId, or materialId."
      );
    }

    const db = admin.firestore();
    const openai = new OpenAI({ apiKey: OPENAI_KEY.value() });

    const courseRef = db
      .collection("users")
      .doc(userId)
      .collection("courses")
      .doc(courseId);

    const materialRef = courseRef.collection("materials").doc(materialId);

    console.log("========== DELETE MATERIAL START ==========");
    console.log("[Input]", req.data);

    // 1️⃣ Load the material document
    const snap = await materialRef.get();
    if (!snap.exists) {
      console.log("[Firestore] Material already deleted.");
      return { message: "Already deleted." };
    }

    const material = snap.data() as {
      storagePath?: string;
      openAiFileId?: string;
      status?: string;
    };

    const { storagePath, openAiFileId, status } = material;

    console.log("[Material] status:", status);
    console.log("[Material] storagePath:", storagePath);
    console.log("[Material] openAiFileId:", openAiFileId);

    // 2️⃣ Prevent deleting while indexing/pending
    if (status === "indexing" || status === "pending") {
      throw new HttpsError(
        "failed-precondition",
        "Cannot delete material while indexing. Please wait until indexing finishes."
      );
    }

    // 3️⃣ Load vector store ID
    const courseSnap = await courseRef.get();
    const courseData = courseSnap.data() as { vectorStoreId?: string };
    const vectorStoreId = courseData?.vectorStoreId;

    console.log("[VectorStore] vectorStoreId:", vectorStoreId);

    // 4️⃣ BEGIN TRY BLOCK
    try {
      // 4.1 Remove from vector store
      if (vectorStoreId && openAiFileId) {
        console.log("[OpenAI] Removing file from vector store...");
        try {
          await openai.vectorStores.files.delete(openAiFileId, {
            vector_store_id: vectorStoreId,
          });
          console.log("[OpenAI] Removed file from vector store.");
        } catch (err: any) {
          console.error("[OpenAI] Failed to remove from vector store:", err);
          const reqId =
            err?.response?.headers?.["x-request-id"] ??
            err?.response?.headers?.get?.("x-request-id");
          if (reqId) console.error("[OpenAI Request ID]:", reqId);
        }
      }

      // 4.2 Delete OpenAI File
      if (openAiFileId) {
        console.log("[OpenAI] Deleting OpenAI file...");
        try {
          await openai.files.delete(openAiFileId);
          console.log("[OpenAI] File deleted from OpenAI.");
        } catch (err: any) {
          console.error("[OpenAI] Failed to delete file:", err);
          const reqId =
            err?.response?.headers?.["x-request-id"] ??
            err?.response?.headers?.get?.("x-request-id");
          if (reqId) console.error("[OpenAI Request ID]:", reqId);
        }
      }

      // 4.3 Delete from Firebase Storage
      if (storagePath) {
        console.log("[Storage] Deleting storage file:", storagePath);
        try {
          await admin.storage().bucket().file(storagePath).delete();
          console.log("[Storage] File deleted.");
        } catch (err) {
          console.error("[Storage] Failed to delete file:", err);
        }
      }

      // 4.4 Delete Firestore material (last)
      console.log("[Firestore] Deleting material document...");
      await materialRef.delete();
      console.log("[Firestore] Material document deleted.");

      console.log("========== DELETE MATERIAL COMPLETE ==========");
      return { message: "Material successfully deleted." };
    } catch (error: any) {
      console.error("========== DELETE MATERIAL ERROR ==========");
      console.error("[Error Message]:", error.message);
      console.error("[Full Error]:", error);

      const requestId =
        error?.response?.headers?.["x-request-id"] ??
        error?.response?.headers?.get?.("x-request-id");
      if (requestId) console.error("[OpenAI Request ID]:", requestId);

      throw new HttpsError(
        "internal",
        `Deletion failed: ${error.message ?? "Unknown error"}`
      );
    }
  }
);

export const deleteCourse = onCall(
  {
    region: "northamerica-northeast2",
    secrets: [OPENAI_KEY],
    timeoutSeconds: 300, // deleting materials may take time
  },
  async (req) => {
    const { userId, courseId } = req.data;

    if (!userId || !courseId) {
      throw new HttpsError("invalid-argument", "Missing userId or courseId.");
    }

    const db = admin.firestore();
    const openai = new OpenAI({ apiKey: OPENAI_KEY.value() });

    const courseRef = db
      .collection("users")
      .doc(userId)
      .collection("courses")
      .doc(courseId);

    console.log("========== DELETE COURSE START ==========");
    console.log("[Input]", req.data);

    // 1️⃣ Load course
    const courseSnap = await courseRef.get();
    if (!courseSnap.exists) {
      console.log("[Firestore] Course already deleted.");
      return { message: "Course already deleted." };
    }

    const courseData = courseSnap.data() as {
      vectorStoreId?: string;
      name?: string;
    };

    const vectorStoreId = courseData.vectorStoreId;

    console.log("[Course] vectorStoreId:", vectorStoreId);

    try {
      // 2️⃣ Load all materials
      console.log("[Firestore] Loading course materials...");
      const materialsSnap = await courseRef.collection("materials").get();
      const materials = materialsSnap.docs;

      console.log(`[Firestore] Found ${materials.length} materials.`);

      // 3️⃣ Loop and delete each material exactly like deleteMaterial
      for (const doc of materials) {
        const materialId = doc.id;
        const material = doc.data() as {
          storagePath?: string;
          openAiFileId?: string;
          status?: string;
        };

        const { storagePath, openAiFileId, status } = material;

        console.log("----- Deleting Material:", materialId);
        console.log("[Material] status:", status);

        // Prevent course deletion while indexing
        if (status === "indexing" || status === "pending") {
          throw new HttpsError(
            "failed-precondition",
            `Material ${materialId} is still indexing. Cannot delete course.`
          );
        }

        // 3.1 Delete vector store reference
        if (vectorStoreId && openAiFileId) {
          try {
            console.log("[OpenAI] Removing file from vector store...");
            await openai.vectorStores.files.delete(openAiFileId, {
              vector_store_id: vectorStoreId,
            });
            console.log("[OpenAI] Removed file from vector store.");
          } catch (err) {
            console.error(
              "[OpenAI] Failed removing file from vector store.",
              err
            );
          }
        }

        // 3.2 Delete OpenAI file
        if (openAiFileId) {
          try {
            console.log("[OpenAI] Deleting OpenAI file...");
            await openai.files.delete(openAiFileId);
            console.log("[OpenAI] OpenAI file deleted.");
          } catch (err) {
            console.error("[OpenAI] Failed deleting OpenAI file.", err);
          }
        }

        // 3.3 Delete from Firebase Storage
        if (storagePath) {
          try {
            console.log("[Storage] Deleting storage file:", storagePath);
            await admin.storage().bucket().file(storagePath).delete();
            console.log("[Storage] Storage file deleted.");
          } catch (err) {
            console.error("[Storage] Failed deleting storage file.", err);
          }
        }

        // 3.4 Delete material Firestore doc
        console.log("[Firestore] Deleting material doc:", materialId);
        await courseRef.collection("materials").doc(materialId).delete();
      }

      // 4️⃣ Delete vector store itself
      if (vectorStoreId) {
        try {
          console.log("[OpenAI] Deleting vector store...");
          await openai.vectorStores.delete(vectorStoreId);
          console.log("[OpenAI] Vector store deleted.");
        } catch (err) {
          console.error("[OpenAI] Failed to delete vector store:", err);
        }
      }

      // 5️⃣ Delete course document LAST
      console.log("[Firestore] Deleting course document...");
      await courseRef.delete();
      console.log("[Firestore] Course deleted.");

      console.log("========== DELETE COURSE COMPLETE ==========");
      return {
        message: "Course successfully deleted along with all materials.",
      };
    } catch (error: any) {
      console.error("========== DELETE COURSE ERROR ==========");
      console.error("[Error Message]:", error.message);
      console.error("[Full Error]:", error);

      const requestId =
        error?.response?.headers?.["x-request-id"] ??
        error?.response?.headers?.get?.("x-request-id");

      if (requestId) console.error("[OpenAI Request ID]:", requestId);

      throw new HttpsError(
        "internal",
        `Failed to delete course: ${error.message ?? "Unknown error"}`
      );
    }
  }
);
