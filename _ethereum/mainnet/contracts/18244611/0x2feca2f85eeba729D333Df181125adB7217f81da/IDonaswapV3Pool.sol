// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./IDonaswapV3PoolImmutables.sol";
import "./IDonaswapV3PoolState.sol";
import "./IDonaswapV3PoolDerivedState.sol";
import "./IDonaswapV3PoolActions.sol";
import "./IDonaswapV3PoolOwnerActions.sol";
import "./IDonaswapV3PoolEvents.sol";

/// @title The interface for a Donaswap V3 Pool
/// @notice A Donaswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IDonaswapV3Pool is
    IDonaswapV3PoolImmutables,
    IDonaswapV3PoolState,
    IDonaswapV3PoolDerivedState,
    IDonaswapV3PoolActions,
    IDonaswapV3PoolOwnerActions,
    IDonaswapV3PoolEvents
{

}
