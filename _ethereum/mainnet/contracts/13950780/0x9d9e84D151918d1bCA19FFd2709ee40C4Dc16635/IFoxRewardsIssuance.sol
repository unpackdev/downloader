// SPDX-License-Identifier: MIT
pragma solidity =0.6.11;

interface IFoxRewardsIssuance {
    function initialize() external;
    function issueRewards() external;
    function calculateRewards() external view returns (uint256, uint256);
}
