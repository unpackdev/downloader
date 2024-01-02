// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Structs.sol";
import "./MathUtil.sol";
import "./SafeCast.sol";

///@title Tax contract
///@notice Handle tax logic, for either a deposit or withdraw compute if the action is unabalacing
/// the protocol
///        if this is the case, the protocol will compute a tax applied on deposit or withdraw by
/// reducing the number of shares to mint
///        or by increasing the number of shares to burn. This tax is then minted to fyde contract.
/// The main logic is that for each action, we compute a taxable amount which is the amount that
/// unbalance the protocol for a given deposit or withdraw,
/// then we apply the tax on this taxable amount.
/// For the swap the logic is the same, we compute the tax and incentive for assetIn and that give
/// the value of assetOut,
/// for this value we compute the tax and incentive for assetOut.
/// SwapRate can be greater for assetOut in case there is no tax and some incentives, the same if no
/// tax no incentive, or lower if there is tax and no incentive.
abstract contract Tax {
  using SafeCastU256 for uint256;
  using SafeCastI256 for int256;

  /*//////////////////////////////////////////////////////////////
                                 MAIN
    //////////////////////////////////////////////////////////////*/

  function _getDepositTax(
    ProcessParam memory processParam,
    uint256 protocolAUM,
    uint256 totalUsdDeposit,
    uint256 taxFactor
  ) internal pure returns (ProcessParam memory) {
    if (processParam.targetConc == 0) {
      processParam.taxInUSD = processParam.usdValue;
      return processParam;
    }
    if (taxFactor == 0) return processParam;
    processParam = _computeDepositTaxableAmount(processParam, protocolAUM, totalUsdDeposit);
    if (processParam.taxableAmount == 0) return processParam;
    processParam = _computeDepositTaxInUSD(processParam, protocolAUM, totalUsdDeposit, taxFactor);
    return processParam;
  }

  function _getWithdrawTax(
    ProcessParam memory processParam,
    uint256 protocolAUM,
    uint256 totalUsdWithdraw,
    uint256 taxFactor
  ) internal pure returns (ProcessParam memory) {
    if (taxFactor == 0) return processParam;
    processParam = _computeWithdrawTaxableAmount(processParam, protocolAUM, totalUsdWithdraw);
    if (processParam.taxableAmount == 0) return processParam;
    processParam = _computeWithdrawTaxInUSD(processParam, protocolAUM, totalUsdWithdraw, taxFactor);
    return processParam;
  }

  function _getSwapRate(
    ProcessParam memory processParamIn,
    ProcessParam memory processParamOut,
    uint256 protocolAUM,
    uint256 taxFactor,
    int256 incentiveFactorIn,
    int256 incentiveFactorOut
  ) internal pure returns (uint256) {
    // Compute tax on deposit
    processParamIn = _getDepositTax(processParamIn, protocolAUM, 0, taxFactor);

    int256 valIn = incentiveFactorIn
      * int256(processParamIn.usdValue - processParamIn.taxableAmount) / int256(1e20);

    // usdValue adjusted with potential tax and incentive
    uint256 withdrawValOut = valIn >= 0
      ? processParamIn.usdValue - processParamIn.taxInUSD + valIn.toUint()
      : processParamIn.usdValue - processParamIn.taxInUSD - (-1 * valIn).toUint();

    processParamOut.usdValue = withdrawValOut;
    processParamOut = _getWithdrawTax(processParamOut, protocolAUM, 0, taxFactor);

    // usdValueOut adjusted with potential tax and incentive
    int256 valOut =
      incentiveFactorOut * int256(withdrawValOut - processParamOut.taxableAmount) / 1e20;

    uint256 usdValOut = valOut >= 0
      ? withdrawValOut - processParamOut.taxInUSD + valOut.toUint()
      : withdrawValOut - processParamOut.taxInUSD - (-1 * valOut).toUint();

    return usdValOut;
  }

  /*//////////////////////////////////////////////////////////////
                                 DEPOSIT
    //////////////////////////////////////////////////////////////*/
  function _computeDepositTaxableAmount(
    ProcessParam memory processParam,
    uint256 protocolAUM,
    uint256 totalUsdDeposit
  ) internal pure returns (ProcessParam memory) {
    int256 deltaConc = protocolAUM.toInt()
      * (processParam.currentConc.toInt() - processParam.targetConc.toInt()) / 1e20;
    int256 targetDeposit = totalUsdDeposit != 0
      ? processParam.targetConc.toInt() * totalUsdDeposit.toInt() / 1e20
      : int256(0);
    int256 tax = processParam.usdValue.toInt() + deltaConc - targetDeposit;
    processParam.taxableAmount =
      MathUtil.min(processParam.usdValue.toInt(), MathUtil.max(tax, int256(0))).toUint();
    return processParam;
  }

  function _computeDepositTaxInUSD(
    ProcessParam memory processParam,
    uint256 protocolAUM,
    uint256 totalUsdDeposit,
    uint256 taxFactor
  ) internal pure returns (ProcessParam memory) {
    uint256 numerator = (protocolAUM * processParam.currentConc / 1e20) + processParam.usdValue;
    uint256 denominator = (protocolAUM + totalUsdDeposit) * processParam.targetConc / 1e20;
    uint256 eq = (1e18 * numerator / denominator) - 1e18;
    uint256 tmpRes = MathUtil.min(eq, 1e18);
    uint256 taxPerc = taxFactor * tmpRes / 1e20; // 1e20 for applying expressing tax as a percentage
    processParam.taxInUSD = processParam.taxableAmount * taxPerc / 1e18;
    return processParam;
  }

  /*//////////////////////////////////////////////////////////////
                                 WITHDRAW
    //////////////////////////////////////////////////////////////*/
  function _computeWithdrawTaxableAmount(
    ProcessParam memory processParam,
    uint256 protocolAUM,
    uint256 totalUsdWithdraw
  ) internal pure returns (ProcessParam memory) {
    int256 deltaConc = protocolAUM.toInt()
      * (processParam.currentConc.toInt() - processParam.targetConc.toInt()) / 1e20;
    int256 targetDeposit = processParam.targetConc.toInt() * totalUsdWithdraw.toInt() / 1e20;
    int256 tax = processParam.usdValue.toInt() - deltaConc - targetDeposit;
    processParam.taxableAmount =
      MathUtil.min(processParam.usdValue.toInt(), MathUtil.max(tax, int256(0))).toUint();
    return processParam;
  }

  function _computeWithdrawTaxInUSD(
    ProcessParam memory processParam,
    uint256 protocolAUM,
    uint256 totalUsdWithdraw,
    uint256 taxFactor
  ) internal pure returns (ProcessParam memory) {
    int256 numerator =
      protocolAUM.toInt() * processParam.currentConc.toInt() / 1e20 - processParam.usdValue.toInt();
    int256 denominator =
      processParam.targetConc.toInt() * (protocolAUM.toInt() - totalUsdWithdraw.toInt()) / 1e20;
    int256 tmpRes = 1e18 - (1e18 * numerator / denominator);
    uint256 tmpRes2 = MathUtil.min(tmpRes.toUint(), 1e18);
    uint256 taxPerc = taxFactor * tmpRes2 / 1e20; // 1e20 for applying expressing tax as a
      // percentage
    processParam.taxInUSD = processParam.taxableAmount * taxPerc / 1e18;
    return processParam;
  }
}
