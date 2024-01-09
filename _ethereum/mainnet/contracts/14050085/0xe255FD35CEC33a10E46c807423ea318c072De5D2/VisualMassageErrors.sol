//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// collect / sale
error CollectInactive();
error AlreadyCollected();
error PrivateEventOnly();

// helixes
error HelixNotConfigured();
error WrongHelix();
error ErrorInIds();
error NotClaimable();

// value
error WrongValue();
error WithdrawError();

// auth
error NotAuthorized();
error WrongSignature();

// config
error ConfigError(string where);
