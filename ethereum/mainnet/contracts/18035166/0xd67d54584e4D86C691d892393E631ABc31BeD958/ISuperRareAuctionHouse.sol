// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author koloz
/// @title ISuperRareAuctionHouse
/// @notice The interface for the SuperRareAuctionHouse Functions.
interface ISuperRareAuctionHouse {
  /// @notice Configures an Auction for a given asset.
  /// @param _auctionType The type of auction being configured.
  /// @param _originContract Contract address of the asset being put up for auction.
  /// @param _tokenId Token Id of the asset.
  /// @param _startingAmount The reserve price or min bid of an auction.
  /// @param _currencyAddress The currency the auction is being conducted in.
  /// @param _lengthOfAuction The amount of time in seconds that the auction is configured for.
  /// @param _splitAddresses Addresses to split the sellers commission with.
  /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
  function configureAuction(
    bytes32 _auctionType,
    address _originContract,
    uint256 _tokenId,
    uint256 _startingAmount,
    address _currencyAddress,
    uint256 _lengthOfAuction,
    uint256 _startTime,
    address payable[] calldata _splitAddresses,
    uint8[] calldata _splitRatios
  ) external;

  /// @notice Converts an offer into a coldie auction.
  /// @param _originContract Contract address of the asset.
  /// @param _tokenId Token Id of the asset.
  /// @param _currencyAddress Address of the currency being converted.
  /// @param _amount Amount being converted into an auction.
  /// @param _lengthOfAuction Number of seconds the auction will last.
  /// @param _splitAddresses Addresses that the sellers take in will be split amongst.
  /// @param _splitRatios Ratios that the take in will be split by.
  function convertOfferToAuction(
    address _originContract,
    uint256 _tokenId,
    address _currencyAddress,
    uint256 _amount,
    uint256 _lengthOfAuction,
    address payable[] calldata _splitAddresses,
    uint8[] calldata _splitRatios
  ) external;

  /// @notice Cancels a configured Auction that has not started.
  /// @param _originContract Contract address of the asset pending auction.
  /// @param _tokenId Token Id of the asset.
  function cancelAuction(address _originContract, uint256 _tokenId) external;

  /// @notice Places a bid on a valid auction.
  /// @param _originContract Contract address of asset being bid on.
  /// @param _tokenId Token Id of the asset.
  /// @param _currencyAddress Address of currency being used to bid.
  /// @param _amount Amount of the currency being used for the bid.
  function bid(
    address _originContract,
    uint256 _tokenId,
    address _currencyAddress,
    uint256 _amount
  ) external payable;

  /// @notice Settles an auction that has ended.
  /// @param _originContract Contract address of asset.
  /// @param _tokenId Token Id of the asset.
  function settleAuction(address _originContract, uint256 _tokenId) external;

  /// @notice Grabs the current auction details for a token.
  /// @param _originContract Contract address of asset.
  /// @param _tokenId Token Id of the asset.
  /** @return Auction Struct: creatorAddress, creationTime, startingTime, lengthOfAuction,
                currencyAddress, minimumBid, auctionType, splitRecipients array, and splitRatios array.
    */
  function getAuctionDetails(address _originContract, uint256 _tokenId)
    external
    view
    returns (
      address,
      uint256,
      uint256,
      uint256,
      address,
      uint256,
      bytes32,
      address payable[] memory,
      uint8[] memory
    );
}
