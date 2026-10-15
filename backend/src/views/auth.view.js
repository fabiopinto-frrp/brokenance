// The "view" of this API: turns database objects into the JSON the app receives.
// Only fields listed here can ever leave the server, so things like `passwordHash`
// cannot leak by accident. The matching zod schemas in schemas/auth.schemas.js document this shape
// and are checked against real responses in the tests.

export const toUserResponse = (user) => ({
  id: user.id,
  username: user.username,
  firstName: user.profile.firstName,
  lastName: user.profile.lastName,
});

export const toTokensResponse = (tokens) => ({
  accessToken: tokens.accessToken,
  accessTokenExpiresAt: tokens.accessTokenExpiresAt.toISOString(),
  refreshToken: tokens.refreshToken,
  refreshTokenExpiresAt: tokens.refreshTokenExpiresAt.toISOString(),
});

export const toSessionResponse = ({ user, tokens }) => ({
  user: toUserResponse(user),
  ...toTokensResponse(tokens),
});
