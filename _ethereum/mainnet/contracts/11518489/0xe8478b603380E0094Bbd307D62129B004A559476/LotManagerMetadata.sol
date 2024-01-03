// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./ILotManagerMetadata.sol";

contract LotManagerMetadata is ILotManagerMetadata {
  function isLotManager() external override pure returns (bool) {
    return true;
  }
  function getName() external override pure returns (string memory) {
    return 'LotManager';
  }
}