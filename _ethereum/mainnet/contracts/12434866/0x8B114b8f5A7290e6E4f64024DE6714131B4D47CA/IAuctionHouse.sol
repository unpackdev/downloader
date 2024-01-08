// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IAuctionHouseState.sol";
import "./IAuctionHouseVariables.sol";
import "./IAuctionHouseDerivedState.sol";
import "./IAuctionHouseActions.sol";
import "./IAuctionHouseGovernedActions.sol";
import "./IAuctionHouseEvents.sol";

/**
 * @title The interface for a Float Protocol Auction House
 * @notice The Auction House enables the sale and buy of FLOAT tokens from the
 * market in order to stabilise price.
 * @dev The Auction House interface is broken up into many smaller pieces
 */
interface IAuctionHouse is
  IAuctionHouseState,
  IAuctionHouseVariables,
  IAuctionHouseDerivedState,
  IAuctionHouseActions,
  IAuctionHouseGovernedActions,
  IAuctionHouseEvents
{

}
