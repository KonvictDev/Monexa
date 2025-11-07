import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {google} from "googleapis";
import {GaxiosError} from "gaxios"; // Correct import for GaxiosError

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Define a type for the specific API error data we expect from Google Play
type GooglePlayErrorResponse = {
  data?: {
    error_description?: string;
    // Use a union type for 'error' to handle both string and object responses
    error?: string | {
      code: number;
      message: string;
      status: string;
    };
  };
};

/**
 * Reads and parses the Google Play service account credentials from
 * the Base64 environment variable (GPLAY_SERVICE_ACCOUNT_BASE64).
 *
 * @return {Record<string, unknown>} Parsed service account credentials.
 * @throws {Error} If decoding or parsing fails or config is missing.
 */
function getGooglePlayServiceAccount(): Record<string, unknown> {
  // Access the secret via process.env after being declared in the secrets array
  const b64Config = process.env.GPLAY_SERVICE_ACCOUNT_BASE64;

  if (!b64Config) {
    logger.error(
      "GPLAY_SERVICE_ACCOUNT_BASE64 environment variable not found."
    );
    throw new Error("Missing Google Play Service Account Credentials.");
  }

  try {
    const decoded = Buffer.from(b64Config, "base64").toString("utf8");

    // CRITICAL FIX: Remove BOM character (\uFEFF) if present before JSON.parse
    const cleanedJson = decoded.trim().replace(/^\uFEFF/g, "");

    const parsed = JSON.parse(cleanedJson);

    logger.info("Configuration JSON decoded successfully.");

    let creds = parsed;
    // Handle the nested structure from your original config output
    if (parsed.google_play && parsed.google_play.service_account_json) {
      creds = parsed.google_play.service_account_json;
      logger.info("Accessing nested service_account_json.");
    }

    // 🛑 FINAL CRITICAL FIX: Robust Newline Replacement for JWT Signing
    if (creds.private_key && typeof creds.private_key === "string") {
      // Step 1: Handle double-escaped newlines (\\\\n -> \n)
      let privateKey = creds.private_key.replace(/\\\\n/g, "\n");
      // Step 2: Handle single-escaped newlines (\\n -> \n)
      privateKey = privateKey.replace(/\\n/g, "\n");

      creds.private_key = privateKey;
      logger.info("Private key lines replaced for robust JWT signature.");
    } else {
      logger.error("Private key field missing or malformed.", {
        keys: Object.keys(creds),
      });
      throw new Error("Private key field missing or malformed in credentials.");
    }

    return creds;
  } catch (err) {
    logger.error("Failed to decode or parse Google Play config:", err);
    throw new Error("Invalid Google Play Service Account Configuration.");
  }
}

/**
 * Verifies a Google Play or App Store purchase token.
 *
 * @param {string} source - The purchase source ("google_play" or "app_store").
 * @param {string} token - The purchase token from the client.
 * @param {string} productId - The product ID of the subscription or item.
 * @return {Promise<boolean>} True if verified successfully.
 */
async function verifyPurchase(
  source: string,
  token: string,
  productId: string
): Promise<boolean> {
  const packageName =
    process.env.ANDROID_PACKAGE_NAME ||
    process.env.APP_PACKAGE_NAME ||
    "com.appsbyanandakumar.billing";

  // --- Enhanced Logging: Verification Input ---
  logger.info("Starting purchase verification.", {
    source,
    productId,
    packageName,
    tokenLength: token.length,
  });
  // ------------------------------------------

  if (source === "google_play") {
    try {
      const credentials = getGooglePlayServiceAccount();

      // --- Enhanced Logging: Service Account Email ---
      logger.info("Service Account Credentials loaded.", {
        client_email: credentials.client_email,
      });
      // ------------------------------------------

      const authClient = new google.auth.JWT({
        email: credentials.client_email as string,
        key: credentials.private_key as string,
        scopes: ["https://www.googleapis.com/auth/androidpublisher"],
      });

      await authClient.authorize();
      logger.info("JWT authorization successful."); // This should now succeed

      const androidPublisher = google.androidpublisher({
        version: "v3",
        auth: authClient,
      });

      // API Call
      const response = await androidPublisher.purchases.subscriptions.get({
        packageName,
        subscriptionId: productId,
        token,
      });

      // --- Enhanced Logging: API Success Response ---
      logger.info("Google Play API Response received.", {
        httpStatus: response.status,
        responseFields: Object.keys(response.data),
      });
      // ------------------------------------------

      const status = response.data;
      const paymentState = status.paymentState ?? null;
      const autoRenewing = status.autoRenewing ?? null;

      const isValidPaymentState = paymentState === 1 || paymentState === 2;
      const isAutoRenewing = autoRenewing === true;
      const isPurchaseValid = Boolean(isValidPaymentState && isAutoRenewing);

      logger.info("Google Play Verification Result:", {
        productId,
        paymentState,
        autoRenewing,
        valid: isPurchaseValid,
      });

      return isPurchaseValid;
    } catch (err: unknown) {
      const error = err as GaxiosError<GooglePlayErrorResponse>;

      // --- CRITICAL Enhanced Logging: API Error ---
      logger.error("Google Play Verification Failed:", {
        message: error.message,
        errorCode: error.code,
        responseBody: error.response?.data,
        stack: error.stack,
      });
      // ------------------------------------------
      return false;
    }
  }

  if (source === "app_store") {
    logger.warn("Apple App Store verification not implemented yet.");
    return true;
  }

  return false;
}

/**
 * Callable function triggered by the Flutter client to verify a purchase
 * and update Firestore with Pro user status.
 */
export const verifySubscription = onCall(
  {
    // Both secrets MUST be listed here to be available in process.env
    secrets: ["ANDROID_PACKAGE_NAME", "GPLAY_SERVICE_ACCOUNT_BASE64"],
  },
  async (request) => {
    const uid = request.auth?.uid;

    // --- Enhanced Logging: Request Start & Auth Check ---
    logger.info("Subscription verification request received.", {
      uid: uid ?? "UNAUTHENTICATED",
      dataKeys: Object.keys(request.data),
    });

    if (!uid) {
      logger.warn("Unauthenticated request blocked.");
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const {purchaseToken, productId, source} = request.data;

    // --- Enhanced Logging: Input Parameters ---
    if (!purchaseToken || !productId || !source) {
      logger.warn("Invalid arguments blocked.", {
        hasToken: !!purchaseToken,
        hasProduct: !!productId,
        hasSource: !!source,
      });
      throw new HttpsError(
        "invalid-argument",
        "Missing required purchase verification parameters."
      );
    }
    // ------------------------------------------

    const isVerified = await verifyPurchase(source, purchaseToken, productId);

    // --- Enhanced Logging: Verification Result ---
    if (!isVerified) {
      logger.error("Final purchase verification failed.");
      throw new HttpsError(
        "permission-denied",
        "Purchase verification failed with the store."
      );
    }
    // ------------------------------------------

    const now = new Date();
    let expiryDate: Date;

    if (productId.includes("monthly")) {
      expiryDate = new Date(now.setMonth(now.getMonth() + 1));
    } else if (productId.includes("annual")) {
      expiryDate = new Date(now.setFullYear(now.getFullYear() + 1));
    } else {
      expiryDate = new Date(now.setDate(now.getDate() + 7));
    }

    await db.collection("users").doc(uid).set(
      {
        isPro: true,
        proExpiry: admin.firestore.Timestamp.fromDate(expiryDate),
        lastSubscriptionId: productId,
        lastVerified: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    logger.info("Subscription successfully granted.", {
      uid,
      productId,
      expiry: expiryDate.toISOString(),
    });

    return {
      success: true,
      message: "Subscription successfully granted.",
    };
  }
);
