// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITradingTokenFactoryV1 {
  function createToken(
    string memory name_, 
    string memory symbol_, 
    uint8 decimals_,
    uint256 totalSupply_,
    address owner_,
    uint256[] memory tokenData) external returns(address);
}
