/**
 * An error that is safe to show to the client. The error handler turns it into
 * `{ "error": { "code": ..., "message": ... } }` with the given HTTP status.
 *
 * `code` is a stable, machine-readable string the app can react to and translate.
 */
export class HttpError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}
