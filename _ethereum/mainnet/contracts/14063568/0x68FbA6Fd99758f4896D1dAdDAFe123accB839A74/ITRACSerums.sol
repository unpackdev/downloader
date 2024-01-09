// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITRACSerums {
  function balanceOf(address, uint256) external view returns (uint256);
  function burnBatch(address, uint256[] calldata, uint256[] calldata) external;
}
