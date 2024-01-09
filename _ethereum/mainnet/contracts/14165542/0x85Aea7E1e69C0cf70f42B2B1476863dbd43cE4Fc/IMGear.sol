// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMGear {
  function renderData(uint256 mgear) external view returns (string memory svg);
}
