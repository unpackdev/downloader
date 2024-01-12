// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBurnable {
  function burn(uint256[] calldata _tokenIds) external;
}