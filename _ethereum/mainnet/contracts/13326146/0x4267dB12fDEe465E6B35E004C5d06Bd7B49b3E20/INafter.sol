// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev Interface for interacting with the Nafter contract that holds Nafter beta tokens.
 */
interface INafter {
  /**
   * @dev Gets the creator of the token
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function creatorOfToken(uint256 _tokenId) external view returns (address payable);

  /**
   * @dev Gets the Service Fee
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function getServiceFee(uint256 _tokenId) external view returns (uint8);

  /**
   * @dev Gets the price type
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @return get the price type
   */
  function getPriceType(uint256 _tokenId, address _owner) external view returns (uint8);

  /**
   * @dev update price only from auction.
   * @param _price price of the token
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   */
  function setPrice(
    uint256 _price,
    uint256 _tokenId,
    address _owner
  ) external;

  /**
   * @dev update bids only from auction.
   * @param _bid bid Amount
   * @param _bidder bidder address
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   */
  function setBid(
    uint256 _bid,
    address _bidder,
    uint256 _tokenId,
    address _owner
  ) external;

  /**
   * @dev remove token from sale
   * @param _tokenId uint256 id of the token.
   * @param _owner owner of the token
   */
  function removeFromSale(uint256 _tokenId, address _owner) external;

  /**
   * @dev get tokenIds length
   */
  function getTokenIdsLength() external view returns (uint256);

  /**
   * @dev get token Id
   * @param _index uint256 index
   */
  function getTokenId(uint256 _index) external view returns (uint256);

  /**
   * @dev Gets the owners
   * @param _tokenId uint256 ID of the token
   */
  function getOwners(uint256 _tokenId) external view returns (address[] memory owners);

  /**
   * @dev Gets the is for sale
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getIsForSale(uint256 _tokenId, address _owner) external view returns (bool);

  // function getTokenInfo(uint256 _tokenId)
  //       external
  //       view
  //       returns (
  //           address,
  //           uint256,
  //           address[] memory,
  //           uint8,
  //           uint256
  // );
  /**
   * @dev add token and set the price.
   * @param _price price of the item.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _tokenId uint256 ID of the token.
   * @param _creator address of the creator
   * @param _minter address of minter
   */
  function addNewTokenAndSetThePriceWithIdAndMinter(
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _tokenId,
    address _creator,
    address _minter
  ) external;

  /**
   * @dev redeem to add a new token.
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 token id
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function verify(
    address _creator,
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode,
    bytes calldata _signature
  ) external view;

  /**
   * @dev set approval for all by MAU.
   * @param _creator address of the creator of the token.
   * @param _operator address of operator
   * @param _approved approve status
   */
  function setApprovalForAllByNMA(
    address _creator,
    address _operator,
    bool _approved
  ) external;
}
