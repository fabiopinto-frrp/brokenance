// The JSON the app receives for the profile. See schemas/profile.schemas.js.

export const toProfileResponse = ({ user, profile, netWorthCents }) => ({
  profile: {
    username: user.username,
    firstName: profile.firstName,
    lastName: profile.lastName,
    monthlyIncomeCents: profile.monthlyIncomeCents,
    netWorthCents,
    netWorthSet: profile.netWorthSetAt !== null,
    currency: profile.currency,
    timezone: profile.timezone,
  },
});
