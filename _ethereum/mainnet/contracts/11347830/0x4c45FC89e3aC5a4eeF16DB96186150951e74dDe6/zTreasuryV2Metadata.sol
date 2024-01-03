// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IZTreasuryV2Metadata.sol";

contract zTreasuryV2Metadata is IZTreasuryV2Metadata {
  function isZTreasury() external override pure returns (bool) {
    return true;
  }
}