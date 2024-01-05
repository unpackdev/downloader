// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./PowerImplLib.sol";

library PowerLib {
  function power(uint256 baseN, uint256 baseD, uint8 expN, uint8 expD) external pure returns (uint256, uint8) {
    return PowerImplLib._power(baseN, baseD, expN, expD);
  }
}
