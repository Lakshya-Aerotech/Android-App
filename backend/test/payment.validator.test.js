const test = require('node:test');
const assert = require('node:assert/strict');
const { PaymentValidator } = require('../dist/validators/payment.validator');

test('accepts a valid server-side payment DTO', () => {
  const result = PaymentValidator.validateCreatePayment({
    bookingId: 'booking-1',
    userId: 'user-1',
    amount: 1250.5,
  });
  assert.equal(result.isValid, true);
  assert.deepEqual(result.errors, []);
});

test('rejects a non-positive payment amount', () => {
  const result = PaymentValidator.validateCreatePayment({
    bookingId: 'booking-1',
    userId: 'user-1',
    amount: 0,
  });
  assert.equal(result.isValid, false);
  assert.match(result.errors.join(' '), /greater than zero/i);
});

test('rejects missing booking and user identifiers', () => {
  const result = PaymentValidator.validateCreatePayment({
    bookingId: '',
    userId: '',
    amount: 10,
  });
  assert.equal(result.isValid, false);
  assert.equal(result.errors.length, 2);
});
