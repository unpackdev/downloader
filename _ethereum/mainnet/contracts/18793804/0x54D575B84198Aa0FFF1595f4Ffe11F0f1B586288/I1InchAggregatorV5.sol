// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./OneInchSwapDescription.sol";


/// @notice I1InchAggregatorV5 
interface I1InchAggregatorV5 {
  function swap(
    address caller,
    OneInchSwapDescription calldata desc,
    bytes calldata permit,
    bytes calldata  data
  ) external returns (uint256 returnAmount, uint256 gasLeft);
}
