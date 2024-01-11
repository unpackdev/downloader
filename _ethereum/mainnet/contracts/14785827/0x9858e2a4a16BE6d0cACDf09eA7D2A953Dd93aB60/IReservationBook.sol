// SPDX-License-Identifier: MIT

////   //////////          //////////////        /////////////////          //////////////
////          /////      /////        /////      ////          /////      /////        /////
////            ///     ////            ////     ////            ////    ////            ////
////           ////     ////            ////     ////            ////    ////            ////
//////////////////      ////            ////     ////            ////    ////            ////
////                    ////     ///    ////     ////            ////    ////     ///    ////
////      ////          ////     /////  ////     ////            ////    ////     /////  ////
////        ////        ////       /////////     ////            ////    ////       /////////
////         /////       /////       //////      ////          /////      /////       //////
////           /////       ////////    ////      ////   //////////          ////////    ////

pragma solidity ^0.8.0;

/**
 * @title IReservationBook
 * @dev Interface for ReservationBook contract for ERC721Dispatcher.
 * @author 0xAnimist (kanon.art)
 */
interface IReservationBook {
  /**
   * @dev Emitted when `tokenId` token is reserved for `reservee` reservee by `payee` payee.
   */
  event Reserved(address indexed payee, address indexed reservee, uint256 startTime, uint256 indexed tokenId, bytes terms, bytes data);

  /**
   *  @dev Reserves `ERC721Delegable` `ERC721DelegableTokenId` token for `_reservee` beginning at `_startTime` with
   * `_terms` terms.
   *
   *  Requirements:
   *
   * - ERC721Delegable token must be deposited.
   * - terms must be acceptable
   * - token must not already be reserved in this time window (NOTE: duration described in terms)
   */
  function reserve(address _reservee, address _ERC721DelegableContract, uint256 _ERC721DelegableTokenId, uint256 _startTime, bytes memory _requestTerms, bytes calldata _data) external payable returns (bool success);

  /**
   *  @dev Returns all reservations for `_tokenId` token.
   *
   *  Requirements:
   *
   * - token must exist.
   */
  function getReservations(uint256 _tokenId) external view returns (address[] memory reservees, uint256[] memory startTimes, bytes[] memory terms);

  /**
   *  @dev Returns `startTime` start time, `terms` terms, and address of
   * `reservee` if `_tokenId` token is reserved at `_time` time.
   *
   *  Requirements:
   *
   * - token must exist.
   */
  function reservedFor(uint256 _time, uint256 _tokenId) external view returns (address reservee, uint256 startTime, uint256 endTime, uint256 index);

  /**
   *  @dev Returns true if `_tokenId` token is reserved between `_startTime` and `_endTime`, as well as the index of the next reservation.
   *
   *  Requirements:
   *
   * - token must exist.
   */
  function isReserved(uint256 _startTime, uint256 _endTime, uint256 _tokenId) external view returns (bool reserved, uint256 nextIndex);

  /**
   *  @dev Returns true if `_requestedTerms` reservation terms requested by `_reservee` reservee on `_tokenId` token are valid.
   */
  function validateReservation(address _reservee, uint256 _tokenId, bytes memory _requestedTerms) external view returns (bool valid);

  /**
   *  @dev Sets the default maxiumum reservations a token can have at a time.
   */
  function setDefaultMaxReservations(uint256 _defaultMaxReservations) external;

  /**
   *  @dev Sets the maxiumum reservations a token can have at a time.
   */
  function setMaxReservations(uint256[] memory _maxReservations, uint256[] memory _tokenIds) external;

  /**
   *  @dev Gets the maxiumum reservations a token can have at a time.
   */
  function getMaxReservations(uint256 _tokenId) external view returns (uint256 maxReservations);

  /**
   *  @dev Withdraws fees accrued for `_tokenId` token in `_currency` currency (where address(0) == ETH) to the caller.
   */
  function claimFeesAccrued(address _currency, uint256 _tokenId) external returns (bool success, uint256 feesClaimedInWei);

  /**
   *  @dev Refunds prepaid fees for all reservations with end times in the future.
   */
  function refundFutureReservations(address _currency, uint256 _tokenId) external;

  /**
   * @dev Removes expired reservations.
   */
  function purgeExpired(uint256 _tokenId) external returns (uint256 reservationsRemaining);
}
