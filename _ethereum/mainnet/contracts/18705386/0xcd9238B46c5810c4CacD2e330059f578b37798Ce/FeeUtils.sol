// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

import "./Constants.sol";
import "./MathUtils.sol";
import "./Errors.sol";

library FeeUtils {

    function _calculateFee(uint256 amountA, uint256 amountB, uint8 feeType, uint256 feeValue, uint256 feeDenominator, uint256 fixedFee)
    internal pure returns (uint256) {
        return _calculateFees(amountA, amountB, feeType, 1, feeValue, feeDenominator, fixedFee);
    }

    function _calculateFees(uint256 amountA, uint256 amountB, uint8 feeType,  uint256 hops, uint256 feeValue, uint256 feeDenominator, uint256 fixedFee)
    internal pure returns (uint256) {
        if (feeType == Constants.FEE_TYPE_TOKEN_B) {
            return MathUtils._mulDiv(amountB, feeValue, feeDenominator) * hops;
        }
        if (feeType == Constants.FEE_TYPE_TOKEN_A) {
            return MathUtils._mulDiv(amountA, feeValue, feeDenominator) * hops;
        }
        if (feeType == Constants.FEE_TYPE_ETH_FIXED) {
            return fixedFee * hops;
        }
        revert Errors.UnknownFeeType(feeType);
    }

}