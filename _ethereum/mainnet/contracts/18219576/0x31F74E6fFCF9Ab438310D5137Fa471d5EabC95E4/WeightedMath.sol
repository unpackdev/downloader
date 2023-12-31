// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "./FixedPoint.sol";

library WeightedMath {
  using FixedPoint for uint256;
  
  // Invariant shrink limit: non-proportional exits cannot cause the invariant to decrease by less than this ratio.
  uint256 internal constant _MIN_INVARIANT_RATIO = 0.7e18;

  function _calcTokenOutGivenExactBptIn(
    uint256 balance,
    uint256 normalizedWeight,
    uint256 bptAmountIn,
    uint256 bptTotalSupply,
    uint256 swapFeePercentage
  ) internal pure returns (uint256) {
    /*****************************************************************************************
    // exactBPTInForTokenOut                                                                //
    // a = amountOut                                                                        //
    // b = balance                     /      /    totalBPT - bptIn       \    (1 / w)  \   //
    // bptIn = bptAmountIn    a = b * |  1 - | --------------------------  | ^           |  //
    // bpt = totalBPT                  \      \       totalBPT            /             /   //
    // w = weight                                                                           //
    *****************************************************************************************/

    // Token out, so we round down overall. The multiplication rounds down, but the power rounds up (so the base
    // rounds up). Because (totalBPT - bptIn) / totalBPT <= 1, the exponent rounds down.

    // Calculate the factor by which the invariant will decrease after burning BPTAmountIn
    uint256 invariantRatio = bptTotalSupply.sub(bptAmountIn).divUp(bptTotalSupply);
    require(invariantRatio >= _MIN_INVARIANT_RATIO, "balancer: MIN_BPT_IN_FOR_TOKEN_OUT");

    // Calculate by how much the token balance has to decrease to match invariantRatio
    uint256 balanceRatio = invariantRatio.powUp(FixedPoint.ONE.divDown(normalizedWeight));

    // Because of rounding up, balanceRatio can be greater than one. Using complement prevents reverts.
    uint256 amountOutWithoutFee = balance.mulDown(balanceRatio.complement());

    // We can now compute how much excess balance is being withdrawn as a result of the virtual swaps, which result
    // in swap fees.

    // Swap fees are typically charged on 'token in', but there is no 'token in' here, so we apply it
    // to 'token out'. This results in slightly larger price impact. Fees are rounded up.
    uint256 taxableAmount = amountOutWithoutFee.mulUp(normalizedWeight.complement());
    uint256 nonTaxableAmount = amountOutWithoutFee.sub(taxableAmount);
    uint256 taxableAmountMinusFees = taxableAmount.mulUp(swapFeePercentage.complement());

    return nonTaxableAmount.add(taxableAmountMinusFees);
  }

  function _calcTokensOutGivenExactBptIn(
    uint256[] memory balances,
    uint256 bptAmountIn,
    uint256 bptTotalSupply
  ) internal pure returns (uint256[] memory) {
    /**********************************************************************************************
    // exactBPTInForTokensOut                                                                    //
    // (per token)                                                                               //
    // aO = amountOut                  /        bptIn         \                                  //
    // b = balance           a0 = b * | ---------------------  |                                 //
    // bptIn = bptAmountIn             \       totalBPT       /                                  //
    // bpt = totalBPT                                                                            //
    **********************************************************************************************/

    uint256[] memory amounts = new uint256[](balances.length);
    for (uint256 i = 0; i < balances.length;) {
      amounts[i] = balances[i].mulDown(bptAmountIn).divDown(bptTotalSupply);
      unchecked { ++i; }
    }
    return amounts;
  }
}