import { onCall } from "firebase-functions/v2/https";
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
    timeoutSeconds: 300, // indexing PDFs may take time
  },
  async (req) => {
    const { userId, courseId, courseName, materialId, storagePath } = req.data;

    if (!userId || !courseId || !materialId || !storagePath) {
      throw new Error(
        "Missing required fields: userId, courseId, materialId, storagePath."
      );
    }

    const openai = new OpenAI({ apiKey: OPENAI_KEY.value() });

    const courseRef = admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("courses")
      .doc(courseId);

    const materialRef = courseRef.collection("materials").doc(materialId);

    // 1️⃣ Get course data
    const courseSnap = await courseRef.get();
    const course = courseSnap.data();

    let vectorStoreId = course?.vectorStoreId ?? null;

    // 2️⃣ Create vector store if missing
    if (!vectorStoreId) {
      console.log("No vector store found. Creating a new one...");

      const store = await openai.vectorStores.create({
        name: `${courseName}_vector_store`,
      });

      vectorStoreId = store.id;

      // update course with vectorStoreId
      await courseRef.update({
        vectorStoreId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // 3️⃣ Download PDF from Firebase Storage to temp file
    const tempLocalFile = path.join(os.tmpdir(), `${materialId}.pdf`);
    await admin.storage().bucket().file(storagePath).download({
      destination: tempLocalFile,
    });

    console.log("Downloaded file to", tempLocalFile);

    // 4️⃣ Upload file to OpenAI Files API
    const fileUpload = await openai.files.create({
      file: fs.createReadStream(tempLocalFile),
      purpose: "assistants",
    });

    const fileId = fileUpload.id;

    console.log("Uploaded file to OpenAI. File ID:", fileId);

    // 5️⃣ Add file to vector store
    await openai.vectorStores.files.create(vectorStoreId, {
      file_id: fileId,
    });

    console.log("Added file to vector store:", vectorStoreId);

    // 6️⃣ Update material doc
    await materialRef.update({
      openAiFileId: fileId,
      status: "indexed",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Cleanup temp file
    fs.unlinkSync(tempLocalFile);

    return {
      vectorStoreId,
      fileId,
      message: "Material successfully indexed.",
    };
  }
);
