// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRenderer {
  function getRarity(uint256 mgear) external pure returns (uint8);

  function getGearName(uint256 mgear) external view returns (uint64);

  function render(uint256 mgear) external view returns (string memory svg);
}
