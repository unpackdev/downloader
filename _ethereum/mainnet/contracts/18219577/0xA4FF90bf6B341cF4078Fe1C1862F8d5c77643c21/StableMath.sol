// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "./FixedPoint.sol";
import "./Math.sol";
import "./BalancerErrors.sol";

library StableMath {
  using FixedPoint for uint256;

  uint256 internal constant _AMP_PRECISION = 1e3;
  
  function _calcTokenOutGivenExactBptIn(
    uint256 amp,
    uint256[] memory balances,
    uint256 tokenIndex,
    uint256 bptAmountIn,
    uint256 bptTotalSupply,
    uint256 currentInvariant,
    uint256 swapFeePercentage
  ) internal pure returns (uint256) {
    // Token out, so we round down overall.

    uint256 newInvariant = bptTotalSupply.sub(bptAmountIn).divUp(bptTotalSupply).mulUp(currentInvariant);

    // Calculate amount out without fee
    uint256 newBalanceTokenIndex = _getTokenBalanceGivenInvariantAndAllOtherBalances(
      amp,
      balances,
      newInvariant,
      tokenIndex
    );
    uint256 amountOutWithoutFee = balances[tokenIndex].sub(newBalanceTokenIndex);

    // First calculate the sum of all token balances, which will be used to calculate
    // the current weight of each token
    uint256 sumBalances = 0;
    for (uint256 i = 0; i < balances.length; i++) {
      sumBalances = sumBalances.add(balances[i]);
    }

    // We can now compute how much excess balance is being withdrawn as a result of the virtual swaps, which result
    // in swap fees.
    uint256 currentWeight = balances[tokenIndex].divDown(sumBalances);
    uint256 taxablePercentage = currentWeight.complement();

    // Swap fees are typically charged on 'token in', but there is no 'token in' here, so we apply it
    // to 'token out'. This results in slightly larger price impact. Fees are rounded up.
    uint256 taxableAmount = amountOutWithoutFee.mulUp(taxablePercentage);
    uint256 nonTaxableAmount = amountOutWithoutFee.sub(taxableAmount);

    // No need to use checked arithmetic for the swap fee, it is guaranteed to be lower than 50%
    return nonTaxableAmount.add(taxableAmount.mulDown(FixedPoint.ONE - swapFeePercentage));
  }

  // This function calculates the balance of a given token (tokenIndex)
    // given all the other balances and the invariant
    function _getTokenBalanceGivenInvariantAndAllOtherBalances(
        uint256 amplificationParameter,
        uint256[] memory balances,
        uint256 invariant,
        uint256 tokenIndex
    ) internal pure returns (uint256) {
        // Rounds result up overall

        uint256 ampTimesTotal = amplificationParameter * balances.length;
        uint256 sum = balances[0];
        uint256 P_D = balances[0] * balances.length;
        for (uint256 j = 1; j < balances.length; j++) {
            P_D = Math.divDown(Math.mul(Math.mul(P_D, balances[j]), balances.length), invariant);
            sum = sum.add(balances[j]);
        }
        // No need to use safe math, based on the loop above `sum` is greater than or equal to `balances[tokenIndex]`
        sum = sum - balances[tokenIndex];

        uint256 inv2 = Math.mul(invariant, invariant);
        // We remove the balance from c by multiplying it
        uint256 c = Math.mul(
            Math.mul(Math.divUp(inv2, Math.mul(ampTimesTotal, P_D)), _AMP_PRECISION),
            balances[tokenIndex]
        );
        uint256 b = sum.add(Math.mul(Math.divDown(invariant, ampTimesTotal), _AMP_PRECISION));

        // We iterate to find the balance
        uint256 prevTokenBalance = 0;
        // We multiply the first iteration outside the loop with the invariant to set the value of the
        // initial approximation.
        uint256 tokenBalance = Math.divUp(inv2.add(c), invariant.add(b));

        for (uint256 i = 0; i < 255; i++) {
            prevTokenBalance = tokenBalance;

            tokenBalance = Math.divUp(
                Math.mul(tokenBalance, tokenBalance).add(c),
                Math.mul(tokenBalance, 2).add(b).sub(invariant)
            );

            if (tokenBalance > prevTokenBalance) {
                if (tokenBalance - prevTokenBalance <= 1) {
                    return tokenBalance;
                }
            } else if (prevTokenBalance - tokenBalance <= 1) {
                return tokenBalance;
            }
        }

        _revert(Errors.STABLE_GET_BALANCE_DIDNT_CONVERGE);
    }
}
