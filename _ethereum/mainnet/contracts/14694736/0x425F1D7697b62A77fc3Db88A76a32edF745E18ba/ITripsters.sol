// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ITripsters {
    function adminMint(uint256 amount, address to) external;
    function totalSupply() external view returns (uint256);
}