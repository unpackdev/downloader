// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ReentrancyGuard.sol";

import "./ISettlementValidator.sol";

import "./IDecaCollectionFactory.sol";
import "./IDecaCollection.sol";
import "./IDecaMintOnDemand.sol";

import "./MintStructs.sol";

/**
 * @notice Allows a creator to mint an NFT to a bidder, without having to pay gas.
 * @dev Utilises EIP712 off-chain signatures to grant a bidder permission to mint a specific token id,
 *      which corresponds to an off-chain upload on Deca.
 * @author 0x-jj, j6i
 */
contract DecaMintOnDemand is ReentrancyGuard, IDecaMintOnDemand {
  /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Deca collection factory contract to create collections.
   */
  IDecaCollectionFactory public immutable factory;

  /**
   * @notice SettlementValidator contract to validate off-chain signatures.
   */
  ISettlementValidator public immutable settlementValidator;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address _factory, address _settlementValidator) {
    factory = IDecaCollectionFactory(_factory);
    settlementValidator = ISettlementValidator(_settlementValidator);
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Creates a new collection via the factory, validates and executes the settlement. If successful, mints the NFT to the bidder.
   *         and sends the creator the Ether.
   * @param settlement Contains all the info required to validate and execute settlement on chain.
   * @param collectionInfo CollectionInfo struct.
   * @param collectionInfoSignature Signature to verify against collection info
   */
  function createCollectionAndSettleBid(
    MintStructs.Settlement calldata settlement,
    MintStructs.CollectionInfo calldata collectionInfo,
    bytes calldata collectionInfoSignature
  ) external payable {
    settlementValidator.validateCollectionInfo(collectionInfo, collectionInfoSignature);

    address collection = factory.createDecaCollection(
      IDecaCollectionFactory.CreateDecaCollectionParams({
        creator: settlement.acceptanceInfo.creatorAddress,
        nonce: collectionInfo.nonce,
        recipients: collectionInfo.royaltyRecipients,
        collectionName: collectionInfo.collectionName,
        collectionSymbol: collectionInfo.collectionSymbol
      })
    );

    if (collection != settlement.acceptanceInfo.collectionAddress) {
      revert CollectionMismatch();
    }

    settleBid(settlement);
  }

  /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Validates and executes a settlement. If successful, mints the NFT to the bidder.
   *         and sends the creator the Ether.
   * @param settlement Contains all the info required to validate and execute settlement on chain.
   */
  function settleBid(MintStructs.Settlement calldata settlement) public payable nonReentrant {
    // Validate bid and acceptance criteria and signatures
    bytes32 bidHash = settlementValidator.validateSettlement(settlement, msg.value, msg.sender);

    emit BidSettled(
      settlement.acceptanceInfo.collectionAddress,
      settlement.bidInfo.bidderAddress,
      settlement.acceptanceInfo.creatorAddress,
      settlement.acceptanceInfo.payslips,
      bidHash,
      settlement.bidInfo.tokenId,
      settlement.bidInfo.priceInWei
    );

    // Mint NFT to bidder address
    IDecaCollection(settlement.acceptanceInfo.collectionAddress).mint(
      settlement.bidInfo.bidderAddress,
      settlement.bidInfo.tokenId
    );

    // Transfer ETH to payees
    uint256 totalPayout = 0;

    for (uint256 i = 0; i < settlement.acceptanceInfo.payslips.length; ) {
      MintStructs.Payslip memory payslip = settlement.acceptanceInfo.payslips[i];
      totalPayout += payslip.amountInWei;
      (bool paymentSuccessful, ) = payslip.recipient.call{value: payslip.amountInWei}("");
      if (!paymentSuccessful) {
        revert TransferFailed();
      }
      unchecked {
        i++;
      }
    }

    // Ensure payouts are correct
    if (totalPayout != settlement.bidInfo.priceInWei) {
      revert PayoutMismatch();
    }

    uint256 excess = msg.value - settlement.bidInfo.priceInWei;

    if (excess > 0) {
      (bool excessReturned, ) = settlement.bidInfo.bidderAddress.call{value: excess}("");
      if (!excessReturned) {
        revert TransferFailed();
      }
    }
  }
}
