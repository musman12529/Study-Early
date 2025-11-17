import { onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import OpenAI from "openai";

admin.initializeApp();

const OPENAI_KEY = defineSecret("OPENAI_API_KEY");

export const createVectorStore = onCall(
  {
    region: "us-central1",
    secrets: [OPENAI_KEY],
  },
  async (req) => {
    const { userId, courseId, courseName } = req.data;

    if (!userId || !courseId) {
      throw new Error("Missing userId or courseId");
    }

    const openai = new OpenAI({ apiKey: OPENAI_KEY.value() });

    console.log(`Creating vector store for ${courseName}`);

    const store = await openai.vectorStores.create({
      name: `${courseName}_vector_store`,
    });

    const vectorStoreId = store.id;

    await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("courses")
      .doc(courseId)
      .update({
        vectorStoreId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return { vectorStoreId };
  }
);
