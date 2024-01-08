// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "./ABDKMath64x64.sol";

/**
 * Tools for calculating rewards.
 * Calculation formula: F=P*(1+i)^n
 */
library Calculator {
    /*
     * calculate rewards
     * steps
     * 1. Calculate rewards by apy
     * 2. Get principal and rewards
     * @param principal principal amount
     * @param n periods for calculating interest,  one second eq to one period
     * @param apy annual percentage yield
     * @return sum of principal and rewards
     */
  function calculator(
        uint256 principal,
        uint256 n,
        uint256 apy
   ) internal pure returns (uint256 amount) {
        int128 div = ABDKMath64x64.divu(apy, 36500 * 1 days); // second rate
        int128 sum = ABDKMath64x64.add(ABDKMath64x64.fromInt(1), div);
        int128 pow = ABDKMath64x64.pow(sum, n);
        uint256 res = ABDKMath64x64.mulu(pow, principal);
        return res;
    }

  function getValueOfRepresentUmi(
      uint256 stakedLpTokens,
      uint256 lpTokenTotalSupply,
      uint112 umiReserve) internal pure returns(uint256) {
      int128 lpRatio = ABDKMath64x64.divu(stakedLpTokens, lpTokenTotalSupply);
      uint256 res = ABDKMath64x64.mulu(lpRatio, uint256(umiReserve));
      return res;
  }

}