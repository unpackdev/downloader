// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./SignatureChecker.sol";
import "./ECDSA.sol";

import "./IDecaCollection.sol";
import "./IRoleAuthority.sol";

import "./MintStructs.sol";
import "./ISettlementValidator.sol";

/**
 * @notice Validates EIP712 off-chain signatures for mint on demand DecaCollection NFTs
 * @author 0x-jj, j6i
 */
contract SettlementValidator is ISettlementValidator {
  using MintStructs for MintStructs.BidInfo;
  using MintStructs for MintStructs.AcceptanceInfo;
  using MintStructs for MintStructs.MintPass;
  using MintStructs for MintStructs.CollectionInfo;

  /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice RoleAuthority contract to determine whether an address has some admin role.
   */
  IRoleAuthority public immutable roleAuthority;

  /**
   * @notice The chain id of the network this contract is deployed on.
   */
  uint256 public immutable chainId;

  /**
   * @notice The EIP-712 domain separator.
   */
  bytes32 public immutable domainSeparator;

  /**
   * @notice A mapping of bid info hashes to whether they have been used.
   */
  mapping(bytes32 => bool) public usedBidInfoHashes;

  /**
   * @notice A mapping of acceptance info hashes to whether they have been used.
   */
  mapping(bytes32 => bool) public usedAcceptanceInfoHashes;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address _roleAuthority, string memory name, string memory version) {
    /* 
      There is no way to update the domain separator, as the contract has no owner or admin.

      If there is a network fork that changes the chain id, a new contract needs to be deployed
      and minting ability of the old one must be revoked.

      In case of a new contract deployment, the version of the new contract MUST be updated,
      so that filled orders from past versions are not valid.  
    */
    domainSeparator = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        block.chainid,
        address(this)
      )
    );
    chainId = block.chainid;
    roleAuthority = IRoleAuthority(_roleAuthority);
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Used to invalidate a bid on chain.
   * @dev Can only be called by the bidder.
   * @param bidInfo Bid info struct.
   */
  function invalidateBid(MintStructs.BidInfo calldata bidInfo) external {
    if (bidInfo.bidderAddress != msg.sender) {
      revert NotAuthorized();
    }

    usedBidInfoHashes[bidInfo.hash()] = true;
  }

  /**
   * @notice Validates a settlement using the bid info, acceptance info, and mint pass
   * @param settlement Contains all the info required to validate and execute settlement on chain.
   * @param msgValue The amount of ETH sent with the transaction.
   * @param msgSender The address of the sender of the transaction.
   * @return bidHash The hash of the bid info.
   */
  function validateSettlement(
    MintStructs.Settlement calldata settlement,
    uint256 msgValue,
    address msgSender
  ) external returns (bytes32 bidHash) {
    if (!roleAuthority.is721Minter(msg.sender)) {
      revert NotAuthorized();
    }

    if (settlement.bidInfo.bidderAddress != msgSender) {
      revert NonBidderSettle();
    }

    if (msgValue < settlement.bidInfo.priceInWei) {
      revert BidPriceNotMet();
    }

    IDecaCollection collection = IDecaCollection(settlement.acceptanceInfo.collectionAddress);

    bidHash = settlement.bidInfo.hash();
    bytes32 acceptanceHash = settlement.acceptanceInfo.hash();

    // Check bid info hash and acceptance info hash haven't been used
    if (usedBidInfoHashes[bidHash] || usedAcceptanceInfoHashes[acceptanceHash]) {
      revert SignatureRepeated();
    }

    // Mark bid info hash and acceptance info hash as used
    usedBidInfoHashes[bidHash] = true;
    usedAcceptanceInfoHashes[acceptanceHash] = true;

    // Check token id hasn't been created already
    if (collection.mintTimestamps(settlement.bidInfo.tokenId) > 0) {
      revert TokenAlreadyCreated();
    }

    // Check creator of the collection is the same as the address signing the acceptance info
    if (collection.creator() != settlement.acceptanceInfo.creatorAddress) {
      revert UnauthorizedAcceptanceSigner();
    }

    // Check bid not expired
    if (settlement.bidInfo.expiresAt < block.timestamp) {
      revert BidExpired();
    }

    // Check mint pass signature has not expired
    if (settlement.mintPass.expiresAt < block.timestamp) {
      revert MintPassExpired();
    }

    // Check mint pass signer is actually allowed to sign
    if (!roleAuthority.isMintPassSigner(settlement.mintPass.signer)) {
      revert UnauthorizedMintPassSigner();
    }

    // Check that the provided bid signature matches the one in the acceptance info
    if (!(keccak256(settlement.bidSignature) == settlement.acceptanceInfo.bidSignatureHash)) {
      revert BidSignatureMismatch();
    }

    // Check that the provided acceptance signature matches the one in the mint pass
    if (!(keccak256(settlement.acceptanceSignature) == settlement.mintPass.acceptanceSignatureHash)) {
      revert AcceptanceSignatureMismatch();
    }

    // Check that the bid info has been signed by the expected address
    if (!_verifySignature(bidHash, settlement.bidSignature, settlement.bidInfo.bidderAddress)) {
      revert BidSignatureInvalid();
    }

    // Check that the acceptance info has been signed by the expected address
    if (!_verifySignature(acceptanceHash, settlement.acceptanceSignature, settlement.acceptanceInfo.creatorAddress)) {
      revert AcceptanceSignatureInvalid();
    }

    // Check mint pass signature has been signed by the expected address
    if (!_verifySignature(settlement.mintPass.hash(), settlement.mintPassSignature, settlement.mintPass.signer)) {
      revert MintPassSignatureInvalid();
    }
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Validates a collection info struct
   * @param collectionInfo Contains all the collection info
   * @param signature Signature used to sign the collection info
   */
  function validateCollectionInfo(
    MintStructs.CollectionInfo calldata collectionInfo,
    bytes calldata signature
  ) external view {
    if (!roleAuthority.is721Minter(msg.sender)) {
      revert NotAuthorized();
    }

    bytes32 collectionInfoHash = collectionInfo.hash();

    // Check mint pass signer is actually allowed to sign
    if (!roleAuthority.isMintPassSigner(collectionInfo.signer)) {
      revert UnauthorizedCollectionInfoSigner();
    }

    if (!_verifySignature(collectionInfoHash, signature, collectionInfo.signer)) {
      revert CollectionInfoSignatureInvalid();
    }
  }

  /*//////////////////////////////////////////////////////////////
                                 INTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Used to verify the chain id, compute the digest, and verify the signature.
   * @dev If chainId is not equal to the cached chain id, it would revert.
   * @param computedHash Hash of order (maker bid or maker ask) or merkle root
   * @param signature Signature of the maker
   * @param signer Signer address
   */
  function _verifySignature(
    bytes32 computedHash,
    bytes calldata signature,
    address signer
  ) internal view returns (bool) {
    if (chainId == block.chainid) {
      return
        SignatureChecker.isValidSignatureNow(signer, ECDSA.toTypedDataHash(domainSeparator, computedHash), signature);
    } else {
      revert ChainIdInvalid();
    }
  }
}
