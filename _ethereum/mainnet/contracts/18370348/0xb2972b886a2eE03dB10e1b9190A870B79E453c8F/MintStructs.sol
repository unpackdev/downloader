// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IDecaCollection.sol";

/**
 * @title MintStructs
 */
library MintStructs {
  /**
   * @notice BidInfo is the struct that provides info about a bid on a Deca Collection item.
   * @dev Token ids are globally unique across all DecaCollections. Contract address is not part of the bid
   *      struct so that creators can move a token's collection before minting it, after receiving a bid
   * @param nonce Global user order nonce for maker orders
   * @param tokenId Id of the token to mint
   * @param expiresAt Timestamp bid expires at
   * @param priceInWei Bid price in wei
   * @param bidderAddress Maker address
   */
  struct BidInfo {
    uint256 nonce;
    uint256 tokenId;
    uint256 expiresAt;
    uint256 priceInWei;
    address bidderAddress;
  }

  /**
   * @notice Payslip is the struct for a payout on settlement.
   * @dev Payslips are paid out in order, if there is not enough balance to pay out the next payslip, the settlement fails.
   * @param amountInWei Amount to pay out in wei
   * @param recipient Address to pay out to
   */
  struct Payslip {
    uint256 amountInWei;
    address recipient;
  }

  /**
   * @notice AcceptanceInfo is the struct for a taker ask/bid order. It contains the parameters required for a direct purchase.
   * @dev AcceptanceInfo struct is matched against a BidInfo struct at the protocol level during settlement.
   * @param nonce Nonce to ensure acceptance signature is not re-used
   * @param bidSignatureHash BidInfo hash signed by taker
   * @param creatorAddress Address of the creator accepting the bid
   * @param collectionAddress Address to mint the token on
   * @param payslips Array of payslips to be paid out on settlement
   */
  struct AcceptanceInfo {
    uint256 nonce;
    bytes32 bidSignatureHash;
    address creatorAddress;
    address collectionAddress;
    Payslip[] payslips;
  }

  /**
   * @notice To enable gasless cancellation of bids, we provide a fast expiring signature that is required during settlement and acts as an off-chain mint pass.
   *        If a user tells Deca they want to cancel their bid, we mark it as cancelled internally and refuse to provide a signature for settlement.
   *        In case a user wants to cancel their bid without going through Deca in case the expiry time isn't short enough, they can do so on chain.
   * @dev bidSignatureHash and acceptanceSignature hashes act as nonces, if either has already been used settlement fails.
   * @param expiresAt Timestamp signature expires at
   * @param bidSignatureHash BidInfo is the struct that provides info about a bid on a Deca Collection item.
   * @param acceptanceSignatureHash AcceptanceInfo struct is matched against a BidInfo struct at the protocol level during settlement.
   * @param signer Address owned by Deca used to sign the message
   */
  struct MintPass {
    uint256 expiresAt;
    bytes32 bidSignatureHash;
    bytes32 acceptanceSignatureHash;
    address signer;
  }

  /**
   * @notice A summary of the settlement data required to mint on demand.
   * @param bidSignature Signature for the bid info
   * @param acceptanceSignature Signature for the acceptance info
   * @param mintPassSignature Signature for the mint pass
   * @param bidInfo BidInfo struct, signed by bidder
   * @param acceptanceInfo AcceptanceInfo struct, signed by creator
   * @param mintPass MintPass struct, signed by Deca
   */
  struct Settlement {
    bytes bidSignature;
    bytes acceptanceSignature;
    bytes mintPassSignature;
    BidInfo bidInfo;
    AcceptanceInfo acceptanceInfo;
    MintPass mintPass;
  }

  /**
   * @notice CollectionInfo is the struct that provides info about a collection being created.
   * @param signer Address owned by Deca used to sign the message
   * @param nonce Nonce for the collection, used to generate the collection address
   * @param collectionName Name of the collection being created
   * @param collectionSymbol Symbol of the collection being created
   * @param royaltyRecipients Array of secondary market royalty recipients
   */
  struct CollectionInfo {
    address signer;
    uint96 nonce;
    string collectionName;
    string collectionSymbol;
    Recipient[] royaltyRecipients;
  }

  /**
   * @notice This is the type hash constant used to compute the maker order hash.
   */
  bytes32 internal constant _BIDINFO_TYPEHASH =
    keccak256(
      "BidInfo("
      "uint256 nonce,"
      "uint256 tokenId,"
      "address bidderAddress,"
      "uint256 expiresAt,"
      "uint256 priceInWei"
      ")"
    );

  /**
   * @dev This is the type hash constant used to compute the taker order hash.
   */
  bytes32 internal constant _ACCEPTANCEINFO_TYPEHASH =
    keccak256(
      "AcceptanceInfo("
      "uint256 nonce,"
      "address creatorAddress,"
      "address collectionAddress,"
      "bytes32 bidSignatureHash,"
      "Payslip[] payslips"
      ")"
      "Payslip(address recipient,uint256 amountInWei)"
    );

  /**
   * @dev This is the type hash constant used to compute the payslip hash.
   */
  bytes32 internal constant _PAYSLIP_TYPEHASH =
    keccak256(
      "Payslip("
      "address recipient,"
      "uint256 amountInWei"
      ")"
    );

  /**
   * @dev This is the type hash constant used to compute the mint pass hash.
   */
  bytes32 internal constant _MINTPASS_TYPEHASH =
    keccak256(
      "MintPass("
      "address signer,"
      "uint256 expiresAt,"
      "bytes32 bidSignatureHash,"
      "bytes32 acceptanceSignatureHash"
      ")"
    );

  /**
   * @dev This is the type hash constant used to compute the collection info hash.
   */
  bytes32 internal constant _COLLECTIONINFO_TYPEHASH =
    keccak256(
      "CollectionInfo("
      "string collectionName,"
      "string collectionSymbol,"
      "uint96 nonce,"
      "address signer,"
      "Recipient[] royaltyRecipients"
      ")"
      "Recipient(address recipient,uint16 bps)"
    );

  /**
   * @dev This is the type hash constant used to compute the recipient hash.
   */
  bytes32 internal constant _RECIPIENT_TYPEHASH =
    keccak256(
      "Recipient("
      "address recipient,"
      "uint16 bps"
      ")"
    );

  /**
   * @notice This function is used to compute the EIP712 hash for a BidInfo struct.
   * @param bidInfo BidInfo struct
   * @return bidInfoHash Hash of the BidInfo struct
   */
  function hash(BidInfo memory bidInfo) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          _BIDINFO_TYPEHASH,
          bidInfo.nonce,
          bidInfo.tokenId,
          bidInfo.bidderAddress,
          bidInfo.expiresAt,
          bidInfo.priceInWei
        )
      );
  }

  /**
   * @notice This function is used to compute the EIP712 hash for an AcceptanceInfo struct.
   * @param acceptanceInfo AcceptanceInfo struct
   * @return acceptanceInfoHash Hash of the AcceptanceInfo struct
   */
  function hash(AcceptanceInfo memory acceptanceInfo) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          _ACCEPTANCEINFO_TYPEHASH,
          acceptanceInfo.nonce,
          acceptanceInfo.creatorAddress,
          acceptanceInfo.collectionAddress,
          acceptanceInfo.bidSignatureHash,
          _encodePayslips(acceptanceInfo.payslips)
        )
      );
  }

  /**
   * @notice This function is used to compute the EIP712 hash for a Payslip struct.
   * @param payslip Payslip struct
   * @return payslipHash Hash of the Payslip struct
   */
  function _encodePayslip(Payslip memory payslip) internal pure returns (bytes32) {
    return keccak256(abi.encode(_PAYSLIP_TYPEHASH, payslip.recipient, payslip.amountInWei));
  }

  /**
   * @notice This function is used to compute the EIP712 hash for an array of Payslip structs.
   * @param payslips Array of Payslip structs
   * @return payslipsHash Hash of the Payslip structs
   */
  function _encodePayslips(Payslip[] memory payslips) internal pure returns (bytes32) {
    bytes32[] memory encodedPayslips = new bytes32[](payslips.length);
    for (uint256 i = 0; i < payslips.length; i++) {
      encodedPayslips[i] = _encodePayslip(payslips[i]);
    }

    return keccak256(abi.encodePacked(encodedPayslips));
  }

  /**
   * @notice This function is used to compute the EIP712 hash for a MintPass struct.
   * @param mintPass MintPass struct
   * @return mintPassHash Hash of the MintPass struct
   */
  function hash(MintPass memory mintPass) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          _MINTPASS_TYPEHASH,
          mintPass.signer,
          mintPass.expiresAt,
          mintPass.bidSignatureHash,
          mintPass.acceptanceSignatureHash
        )
      );
  }

  /**
   * @notice This function is used to compute the EIP712 hash for a CollectionInfo struct.
   * @param collectionInfo CollectionInfo struct
   * @return collectionInfoHash Hash of the CollectionInfo struct
   */
  function hash(CollectionInfo memory collectionInfo) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          _COLLECTIONINFO_TYPEHASH,
          keccak256(bytes(collectionInfo.collectionName)),
          keccak256(bytes(collectionInfo.collectionSymbol)),
          collectionInfo.nonce,
          collectionInfo.signer,
          _encodeRecipients(collectionInfo.royaltyRecipients)
        )
      );
  }

  /**
   * @notice This function is used to compute the EIP712 hash for a Recipient struct.
   * @param recipient Recipient struct
   * @return recipientHash Hash of the Recipient struct
   */
  function _encodeRecipient(Recipient memory recipient) internal pure returns (bytes32) {
    return keccak256(abi.encode(_RECIPIENT_TYPEHASH, recipient.recipient, recipient.bps));
  }

  /**
   * @notice This function is used to compute the EIP712 hash for an array of Recipient structs.
   * @param recipients Array of Recipient structs
   * @return recipientsHash Hash of the Recipient structs
   */
  function _encodeRecipients(Recipient[] memory recipients) internal pure returns (bytes32) {
    bytes32[] memory encodedRecipients = new bytes32[](recipients.length);
    for (uint256 i = 0; i < recipients.length; i++) {
      encodedRecipients[i] = _encodeRecipient(recipients[i]);
    }

    return keccak256(abi.encodePacked(encodedRecipients));
  }
}
