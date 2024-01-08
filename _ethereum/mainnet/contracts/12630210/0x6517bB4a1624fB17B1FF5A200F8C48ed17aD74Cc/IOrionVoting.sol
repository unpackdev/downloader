// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

interface IOrionVoting {
    function getPoolRewards(address pool_address) external view returns (uint256);
    function claimRewards(uint56 amount, address to) external;
}
