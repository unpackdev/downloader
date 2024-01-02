// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface INpYieldEngine {
    function yield(address _user, uint256 _amount) external returns (uint256 yieldAmount);

    function estimateCollateralToCore(uint256 collateralAmount) external view returns (uint256 coreAmount);
}
