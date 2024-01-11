// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./IAaveV2LendingPool.sol";
import "./IERC20Minimal.sol";

interface IAaveFCM { 
    
    function aaveLendingPool() external returns (IAaveV2LendingPool);

    function underlyingYieldBearingToken() external returns (IERC20Minimal); 
}