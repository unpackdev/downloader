// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Error {
    error AlreadyInitialized();
    error ZeroAddress();
    error ZeroAmount();
    error ArrayLengthMismatch();
    error AddFailed();
    error RemoveFailed();
    error Unauthorized();
    error UnknownTemplate();
    error DeployerNotFound();
    error PoolNotRejected();
    error PoolNotApproved();
    error DepositsDisabled();
    error WithdrawalsDisabled();
    error InsufficientBalance();
    error MaxStakePerAddressExceeded();
    error MaxStakePerPoolExceeded();
    error FeeTooHigh();
    error MismatchRegistry();
    error InvalidStatus();
}
