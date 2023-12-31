// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IProtectionPlan {
    error IPFSDoesNotExist();
    error UserNotAuthorized();
    error SignerAddressZero();
    error NonceAlreadyUsed();
    error DeadlineExceeded();
    error InvalidSignature();
    error WalletsApprovalsLengthMismatch();
    error BeneficiaryWalletsLengthMismatch();
    error InvalidBeneficiary();
    error WillNotApproved();
    error InsufficientAllowance();
    error InvalidAssetOwner();
    function initialize(address owner, address protocolRegistry) external;
}
