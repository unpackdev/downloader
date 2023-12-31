// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @dev custom error codes common to many contracts are predefined here
 */
interface IFUSIONErrorCodes {
    error FUSION__AmountIsTooBig();
    error FUSION__InsufficientMintPrice();
    error FUSION__InsufficientMintsLeft();
    error FUSION__InvalidMerkleProof();
    error FUSION__MismatchedArrayLengths();
    error FUSION__MintAmountIsTooSmall();
    error FUSION__MustMintWithinMaxSupply();
    error FUSION__NotFusionable();
    error FUSION__NotReadyYet();
    error FUSION__NotTokenOwner();
    error FUSION__WithdrawFailed();
}
