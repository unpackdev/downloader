// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Error contract
/// @dev Contracts should inherit from this contract to use custom errors
contract Error {
    error CanNotTransfer();
    error CanNotApprove();
    error OnlySpaceFactory();
    error OnlySpaceFactoryOrOwner();
    error InvalidTokenId();
    error InvalidTokenURI();
    error InvalidAddress();
    error InvalidListLength();
    error OnlyOneProtoshipAtATime();
    error OnlyNFTOwner();
    error InvalidProtoship();
    error AddressAlreadyRegistered();
    error NotWhiteListed();
    error TokenLocked();
    error OnlyLockedToken();
    error ReachedMaxSupply();
    error OnlyExistingToken();
    error TokenAlreadyMinted();
    error OnlyDuringRefundPeriod();
    error OnlySpaceshipOwner();
    error ExceedMaxContributionPerMint();
    error ExceedMaxContributionPerUser();
    error ExceedMaxTotalContribution();
    error InvalidSignature();
    error NotDuringRefundPeriod();
}
