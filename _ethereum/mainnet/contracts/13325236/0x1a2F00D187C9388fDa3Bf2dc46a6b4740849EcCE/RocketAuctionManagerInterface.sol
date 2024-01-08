/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketAuctionManagerInterface {
    function getTotalRPLBalance() external view returns (uint256);
    function getAllottedRPLBalance() external view returns (uint256);
    function getRemainingRPLBalance() external view returns (uint256);
    function getLotCount() external view returns (uint256);
    function getLotExists(uint256 _index) external view returns (bool);
    function getLotStartBlock(uint256 _index) external view returns (uint256);
    function getLotEndBlock(uint256 _index) external view returns (uint256);
    function getLotStartPrice(uint256 _index) external view returns (uint256);
    function getLotReservePrice(uint256 _index) external view returns (uint256);
    function getLotTotalRPLAmount(uint256 _index) external view returns (uint256);
    function getLotTotalBidAmount(uint256 _index) external view returns (uint256);
    function getLotAddressBidAmount(uint256 _index, address _bidder) external view returns (uint256);
    function getLotRPLRecovered(uint256 _index) external view returns (bool);
    function getLotPriceAtBlock(uint256 _index, uint256 _block) external view returns (uint256);
    function getLotPriceAtCurrentBlock(uint256 _index) external view returns (uint256);
    function getLotPriceByTotalBids(uint256 _index) external view returns (uint256);
    function getLotCurrentPrice(uint256 _index) external view returns (uint256);
    function getLotClaimedRPLAmount(uint256 _index) external view returns (uint256);
    function getLotRemainingRPLAmount(uint256 _index) external view returns (uint256);
    function getLotIsCleared(uint256 _index) external view returns (bool);
    function createLot() external;
    function placeBid(uint256 _lotIndex) external payable;
    function claimBid(uint256 _lotIndex) external;
    function recoverUnclaimedRPL(uint256 _lotIndex) external;
}
