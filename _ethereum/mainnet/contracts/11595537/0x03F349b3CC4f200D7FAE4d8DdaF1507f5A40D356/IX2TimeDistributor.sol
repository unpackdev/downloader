// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2TimeDistributor {
    function getDistributionAmount(address receiver) external view returns (uint256);
    function ethPerInterval(address receiver) external view returns (uint256);
    function lastDistributionTime(address receiver) external view returns (uint256);
}
