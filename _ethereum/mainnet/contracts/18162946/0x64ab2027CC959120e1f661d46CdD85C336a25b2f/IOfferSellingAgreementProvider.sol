// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

struct Offer {
  /// @notice The address of the NFT contract.
  address nftContract;
  /// @notice The id of the NFT.
  uint256 tokenId;
  /// @notice The address of the wallet placing the offer.
  address buyer;
  /// @notice The amount the buyer is willing to pay for the NFT.
  uint256 offerPrice;
}

interface IOfferSellingAgreementProvider {
  /**
   * @notice Emitted when an offer selling agreement is created by a buyer..
   *
   * @param nftContract   : The address of the contract that minted the NFT.
   * @param tokenId       : The ID of the NFT within the contract.
   * @param buyer         : The address of the buyer who created the selling agreement.
   * @param price         : The offer amount.
   * @param id            : Unique identifier of the sale.
   */
  event OfferSellingAgreementCreated(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 price,
    uint256 id
  );

  /**
   * @notice Emitted when an offer selling agreement is cancelled by the buyer.
   *
   * @param nftContract   : The address of the contract that minted the NFT.
   * @param tokenId       : The ID of the NFT within the contract.
   * @param buyer         : The address of the buyer who created the selling agreement.
   * @param price         : The offer amount.
   * @param id            : Unique identifier of the sale.
   */
  event OfferSellingAgreementCancelled(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed buyer,
    uint256 price,
    uint256 id
  );

  /**
   * @notice Emitted when an offer selling agreement is created by a buyer.
   *
   * @param nftContract   : The address of the contract that minted the NFT.
   * @param tokenId       : The ID of the NFT within the contract.
   * @param seller        : The address of the seller who accepted the trade.
   * @param buyer         : The address of the buyer who created the selling agreement.
   * @param price         : The offer amount.
   * @param isPrimarySale : Whether this is a primary or secondary sale. Relevant for revenue split.
   * @param id            : Unique identifier of the sale.
   */
  event OfferSellingAgreementAccepted(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed seller,
    address buyer,
    uint256 price,
    bool isPrimarySale,
    uint256 id
  );

  /**
   * @notice Allows a buyer to place an offer for an NFT.
   *
   * @param nftContract   : The address of the contract that minted the NFT.
   * @param tokenId       : The ID of the NFT within the contract.
   * @param offerAmount   : The ID of the NFT within the contract.
   */
  function createOfferSellingAgreement(
    address nftContract,
    uint256 tokenId,
    uint256 offerAmount
  ) external payable;

  /**
   * @notice Allows a buyer to cancel their offer for a specific NFT.
   * @param offerId   : The ID of the offer to cancel.
   */
  function cancelOfferSellingAgreement(uint256 offerId) external;

  /**
   * @notice Allows the owner of an NFT to accept an offer placed on that NFT
   * @param offerId   : The ID of the offer to accept.
   */
  function acceptOfferSellingAgreement(
    uint256 offerId,
    bool isPrimarySale
  ) external;

  function getOfferSellingAgreementDetails(
    uint256 offerId
  )
    external
    view
    returns (
      address nftContract,
      uint256 tokenId,
      address buyer,
      uint256 offerAmount
    );
}
