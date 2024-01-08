// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./BaseStrategy.sol";

import "./IERC20.sol";
import "./Address.sol";
import "./Math.sol";
import "./IUniswapV3Pool.sol";

import "./IGenericLender.sol";
import "./IOracle.sol";

/// @title StrategyEvents
/// @author Angle Core Team
/// @notice Events used in `Strategy` contracts
contract StrategyEvents {
    event AddLender(address indexed lender);

    event RemoveLender(address indexed lender);
}
