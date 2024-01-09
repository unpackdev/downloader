// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./SafeMathUpgradeable.sol";

/**
 * @title Safe math library for the TANSO token.
 *
 * This library takes care of the bit tricky cases that OpenZeppelin's SafeMathUpgradeable.sol doesn't cover
 * such as "A * B / C".
 */
library TANSOSafeMath_v1 {
  using SafeMathUpgradeable for uint256;

  /**
   * Tries to calculate "A * B / C".
   *
   * This function prevents overflow in the 1st operator, which is "A * B", by switching the order of the operator.
   * i.e., if "(A * B) / C" fails, then tries "(A / C) * B".
   *
   * @param A The 1st operand.
   * @param B The 2nd operand.
   * @param C The 3rd operand.
   * @return True if the calculation succeeds, false if the calculation fails.
   * @return The calculated result.
   */
  function tryAmulBdivC(uint256 A, uint256 B, uint256 C) internal pure returns (bool, uint256) {
    // Tries "A * B" as the 1st step.
    (bool isAmulBSuccess, uint256 AmulB) = A.tryMul(B);

    if (isAmulBSuccess) {
      // If "A * B" in the 1st step was success, executes "(A * B) / C" as the 2nd step.
      (bool isAmulBdivCSuccess, uint256 AmulBdivC) = AmulB.tryDiv(C);
      return (isAmulBdivCSuccess, (isAmulBdivCSuccess ? AmulBdivC : 0));
    } else {
      // If "A * B" in the 1st step was fail, then tries "A / C" as the 1st step instead.
      (bool isAdivCSuccess, uint256 AdivC) = A.tryDiv(C);

      if (isAdivCSuccess) {
        // If "A / C" in the 1st step was success, executes "(A / C) * B" as the 2nd step.
        (bool isAdivCmulBSuccess, uint256 AdivCmulB) = AdivC.tryMul(B);
        return (isAdivCmulBSuccess, (isAdivCmulBSuccess ? AdivCmulB : 0));
      } else {
        // If "A / C" in the 1st step was fail, then returns fail.
        return (false, 0);
      }
    }
  }
}
