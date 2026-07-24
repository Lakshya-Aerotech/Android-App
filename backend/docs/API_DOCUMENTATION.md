# Lakshya Aerotech Backend - PhonePe Payment Gateway Integration

## Overview
This document describes the production REST API endpoints for the PhonePe Payment Gateway integration within the Lakshya Aerotech backend.

---

## Standard Response Structures

### Success Response (HTTP 200 / 201)
```json
{
  "success": true,
  "message": "Descriptive success message",
  "data": { ... },
  "requestId": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Failure Response (HTTP 400 / 404 / 500)
```json
{
  "success": false,
  "message": "Descriptive error message",
  "data": null,
  "requestId": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

## Endpoints

### 1. Health Check
* **Route:** `GET /health`
* **Rate Limit:** Unrestricted
* **Description:** Used by load balancers and deployment diagnostics to verify backend status.
* **Success Response (HTTP 200):**
```json
{
  "success": true,
  "message": "Backend is running",
  "requestId": "req_12345"
}
```

---

### 2. Initiate Payment
* **Route:** `POST /api/payment/create`
* **Rate Limit:** 20 requests / 15 minutes per IP
* **Headers:** `Content-Type: application/json`
* **Request Body:**
```json
{
  "bookingId": "BOOKING_1001",
  "userId": "USER_FARMER_501",
  "amount": 500,
  "mobileNumber": "9876543210"
}
```
* **Validation Rules:**
  - `bookingId`: Non-empty string (Required)
  - `userId`: Non-empty string (Required)
  - `amount`: Number strictly greater than `0` (Required)
* **Success Response (HTTP 200):**
```json
{
  "success": true,
  "message": "Payment initiated successfully.",
  "data": {
    "success": true,
    "merchantTransactionId": "MT_1773000000000_A1B2C3D4",
    "paymentUrl": "https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/pay/...",
    "paymentToken": "https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/pay/...",
    "status": "PENDING"
  },
  "requestId": "req_56789"
}
```

---

### 3. Check Payment Status (Reconciliation)
* **Route:** `GET /api/payment/status/:merchantTransactionId`
* **Rate Limit:** 60 requests / 15 minutes per IP
* **URL Params:** `merchantTransactionId` (String, Required)
* **Description:** Queries PhonePe API directly. If gateway status is final (`SUCCESS` or `FAILED`) and Firestore status is `PENDING`, automatically reconciles Firestore document and booking payment status.
* **Success Response (HTTP 200):**
```json
{
  "success": true,
  "message": "Transaction status retrieved successfully.",
  "data": {
    "success": true,
    "code": "PAYMENT_SUCCESS",
    "message": "Your request has been successfully processed.",
    "data": {
      "merchantId": "YOUR_MERCHANT_ID",
      "merchantTransactionId": "MT_1773000000000_A1B2C3D4",
      "transactionId": "T24072412000001",
      "amount": 50000,
      "paymentState": "COMPLETED",
      "responseCode": "SUCCESS"
    }
  },
  "requestId": "req_67890"
}
```

---

### 4. PhonePe Webhook Callback (Primary Source of Truth)
* **Route:** `POST /api/payment/webhook`
* **Rate Limit:** 120 requests / 15 minutes per IP
* **Headers:** `X-VERIFY: <SHA256(Base64Body + SaltKey) + "###" + SaltIndex>`
* **Request Body:**
```json
{
  "response": "eyJzdWNjZXNzIjp0cnVlLCJjb2RlIjoiUEFZTUVOVF9TVUNDRVNTIiwiZGF0YSI6eyJtZXJjaGFudFRyYW5zYWN0aW9uSWQiOiJNVF8xNzczMDAwMDAwMDAwX0ExQjJDM0Q0IiwidHJhbnNhY3Rpb25JZCI6IlQyNDA3MjQxMjAwMDAwMSIsInBheW1lbnRTdGF0ZSI6IkNPTVBMRVRFRCJ9fQ=="
}
```
* **Processing:**
  1. Verifies timing-safe X-VERIFY signature.
  2. Decodes Base64 response payload.
  3. Checks idempotency: If payment state is already `SUCCESS`, skips duplicate mutations.
  4. Runs an atomic Firestore transaction (`db.runTransaction`) updating `payments/{id}` and `bookings/{id}`.
* **Success Response (HTTP 200):**
```json
{
  "success": true,
  "message": "Webhook processed successfully.",
  "data": null,
  "requestId": "req_99999"
}
```
