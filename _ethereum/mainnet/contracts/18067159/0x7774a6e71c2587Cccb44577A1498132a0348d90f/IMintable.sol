// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMintable {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint(address mintReceiver, uint256 amount) external;
    function totalSupply() external returns (uint256);
}