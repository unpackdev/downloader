// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IGatorV1CustomerActions.sol";
import "./IGatorV1Events.sol";
import "./IGatorV1GatorActions.sol";
import "./IGatorV1Immutables.sol";
import "./IGatorV1MarketorActions.sol";
import "./IGatorV1State.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface ITTSwapV1Gator is
    IGatorV1CustomerActions,
    IGatorV1Events,
    IGatorV1GatorActions,
    IGatorV1Immutables,
    IGatorV1MarketorActions,
    IGatorV1State
{

}
