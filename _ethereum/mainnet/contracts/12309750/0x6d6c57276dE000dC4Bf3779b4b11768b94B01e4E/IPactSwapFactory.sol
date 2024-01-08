// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IUniswapV2Factory.sol";
import "./IGovernanceOwnable.sol";
import "./IWithIncentivesPool.sol";

interface IPactSwapFactory is IUniswapV2Factory, IWithIncentivesPool, IGovernanceOwnable {
}
