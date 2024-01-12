// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./IERC1155.sol";

interface IMintPass is IERC1155 {
  function burn(address _account, uint256 _id, uint256 _value) external;
}