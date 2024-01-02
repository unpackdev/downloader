// SPDX-License-Identifier: UNLICENSED
// Powered by Agora

pragma solidity ^0.8.21;

interface IAgoraErrors {

    error NotEnoughBalance();

    error CallerIsNotTheOwner();
    error CannotSetNewOwnerToTheZeroAddress();
    error TaxesCanNotBeRaised();
    error ApproveFromTheZeroAddress();
    error ApproveToTheZeroAddress();
    error OperationNotAllowed();
    error BurnFromTheZeroAddress();
    error BurnExceedsBalance();
    error MintToZeroAddress();
    error LpTokensExceedsTotalSupply();
    error TooFewLPTokens();
    error LPAlreadyCreated();
    error NotEnoughFundsForLP();
    error HardCapIsTooHigh();
    error LPNotInit();
    error TransactionIsTooBig();
    error LimitsLoweringIsNotAllowed();
    error MaxWalletExceeded();
    error InsufficientAllowance();
}
