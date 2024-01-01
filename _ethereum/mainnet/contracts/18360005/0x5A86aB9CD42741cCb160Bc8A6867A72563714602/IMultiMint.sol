// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "./Type.sol";

interface IMultiMint {
  function multiMint(
    address to_,
    uint256 tier_,
    uint256 count_
  ) external;

  function destroy(
    address payable to_
  ) external;
}