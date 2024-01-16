// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IAirdrop {
    function sdaoToken() external view returns (address token);
    function airdropUsers(address user) external view returns (uint256 claimable);

    function withdrawToken(uint256 value) external;
    function addAddresses(address[] calldata _addresses, uint256[] calldata _rewards) external;
    function removeAddresses(address[] calldata _addresses) external;

    function claim() external;
}