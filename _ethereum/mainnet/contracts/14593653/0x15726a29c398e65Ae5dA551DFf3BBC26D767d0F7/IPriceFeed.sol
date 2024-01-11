// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceFeed {
  // --- Function ---
  function fetchPrice() external view returns (uint256);
}
