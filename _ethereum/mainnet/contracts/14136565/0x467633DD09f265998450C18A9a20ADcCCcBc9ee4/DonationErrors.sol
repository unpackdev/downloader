//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// Error thrown when a call to donate does not have a valid cause
error InvalidCause();

/// Error thrown when a call to donate does not include a value
error InvalidDonationAmount();

/// Error thrown when a call to update limits contains a maximum that is less than the minimum
error InvalidLimitsSpecified();
