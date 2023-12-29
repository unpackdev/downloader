// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./AToken.sol";
import "./ILendingPool.sol";
import "./IAaveIncentivesController.sol";

contract MockAToken is AToken {
  function getRevision() internal pure override returns (uint256) {
    return 0x2;
  }
}
