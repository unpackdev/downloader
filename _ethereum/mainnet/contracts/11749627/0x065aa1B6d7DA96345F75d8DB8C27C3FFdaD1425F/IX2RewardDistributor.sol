// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2RewardDistributor {
    function getDistributionAmount(address receiver) external view returns (uint256);
    function tokensPerInterval(address receiver) external view returns (uint256);
    function lastDistributionTime(address receiver) external view returns (uint256);
}
