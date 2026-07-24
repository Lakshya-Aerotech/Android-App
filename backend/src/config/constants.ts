export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  INTERNAL_SERVER_ERROR: 500,
} as const;

export const RESPONSE_MESSAGES = {
  HEALTH_CHECK_OK: 'Backend is running',
  INTERNAL_SERVER_ERROR: 'An internal server error occurred.',
  UNHANDLED_EXCEPTION: 'Unknown system exception.',
} as const;

export const USER_ROLES = {
  ADMIN: 'admin',
  FARMER: 'farmer',
  RETAILER: 'retailer',
  PILOT: 'pilot',
  EXTERNAL_PILOT: 'external_pilot',
} as const;
