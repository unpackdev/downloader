// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ILair.sol";

interface ILairV2 is ILair {
  function randomVampireOwner(uint256 seed) external view returns (address);
}