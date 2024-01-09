// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0 || ^0.8.0;

interface ITheColors {
  function getHexColor(uint256) external view returns (bytes memory);

  function uintToHexString(uint256) external pure returns (string memory);
}
