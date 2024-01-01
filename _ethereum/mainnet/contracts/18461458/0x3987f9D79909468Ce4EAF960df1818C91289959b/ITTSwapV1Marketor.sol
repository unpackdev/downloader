// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarketorV1Events.sol";
import "./IMarketorV1Immutables.sol";
import "./IMarketorV1MarketCreatorActions.sol";
import "./IMarketorV1State.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface ITTSwapV1Marketor is
    IMarketorV1Events,
    IMarketorV1Immutables,
    IMarketorV1MarketCreatorActions,
    IMarketorV1State
{

}
