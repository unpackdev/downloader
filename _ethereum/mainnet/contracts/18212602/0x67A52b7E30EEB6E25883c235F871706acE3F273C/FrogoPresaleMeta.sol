// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FrogoPresaleMeta {
    error AmountLowError();
    error AmountHighError();
    error PresaleInactive();
    error ContributionAmountExceeded();
    error InvalidPresaleConfig();
    error InvalidContributionConfig();
    error InvalidRefCode();
    error RefCodeAlreadyRegistered();
    error InvalidRefCodeOwner();
    error HardCapReached();
    error PresaleIsNotFinalized();
    error PresaleAlreadyFinalized();
    error NothingToClaim();
    error InvalidPriceFeedAddress();
    error InvalidDepositToken();
}
