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
