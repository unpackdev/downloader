// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./MintStructs.sol";

interface ISettlementValidator {
  error ChainIdInvalid();
  error SignatureRepeated();
  error BidSignatureMismatch();
  error AcceptanceSignatureMismatch();
  error BidExpired();
  error MintPassExpired();
  error UnauthorizedMintPassSigner();
  error UnauthorizedAcceptanceSigner();
  error MintPassSignatureInvalid();
  error BidSignatureInvalid();
  error AcceptanceSignatureInvalid();
  error NotAuthorized();
  error TokenAlreadyCreated();
  error BidPriceNotMet();
  error NonBidderSettle();
  error UnauthorizedCollectionInfoSigner();
  error CollectionInfoSignatureInvalid();

  function usedBidInfoHashes(bytes32 _hash) external view returns (bool);

  function usedAcceptanceInfoHashes(bytes32 _hash) external view returns (bool);

  function invalidateBid(MintStructs.BidInfo calldata bidInfo) external;

  function validateSettlement(
    MintStructs.Settlement calldata settlement,
    uint256 msgValue,
    address msgSender
  ) external returns (bytes32 hash);

  function validateCollectionInfo(
    MintStructs.CollectionInfo calldata collectionInfo,
    bytes calldata signature
  ) external view;
}
