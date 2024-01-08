// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IBasketBalancer {
    function addToken(address, uint256) external returns (uint256);

    function hasVotedInEpoch(address, uint128) external view returns (bool);

    function getTargetAllocation(address) external view returns (uint256);

    function full_allocation() external view returns (uint256);

    function updateBasketBalance() external;

    function reignDiamond() external view returns (address);

    function getTokens() external view returns (address[] memory);
}
