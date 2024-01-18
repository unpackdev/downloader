// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

interface IBentoBoxOwner {
    function setStrategyTargetPercentageAndRebalance(IERC20 token, uint64 targetPercentage) external;
}
