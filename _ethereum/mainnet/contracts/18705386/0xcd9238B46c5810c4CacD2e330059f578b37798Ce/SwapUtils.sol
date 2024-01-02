// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

import "./Constants.sol";
import "./Errors.sol";
import "./FeeUtils.sol";
import "./MathUtils.sol";

library SwapUtils {

    struct Swap {
        uint256 amountA;
        uint256 amountB;
        bool isPartial;
        uint8 feeType;
        uint32 start;
        uint32 expiration;
        address maker;
        address tokenA;
        address tokenB;
    }

    struct Claim {
        uint256 swapId;
        uint256 amountA;
        uint256 amountB;
    }

    struct MultiClaim {
        uint256 amountA;
        uint256 amountB;
        address tokenA;
        address tokenB;
        uint256[] swapIds;
    }

    struct ClaimInput {
        uint256 swapId;
        uint256 amountB;
    }

    struct MultiClaimInput {
        uint256 amountB;
        address tokenA;
        address tokenB;
        uint256[] swapIds;
    }

    struct SwapCalculation {
        uint256 amountA;
        uint256 amountB;
        uint256 fee;
        uint256 nativeSendAmount;
        uint8 feeType;
        bool isTokenBNative;
        bool isComplete;
    }

    function _checkSwap(address tokenA, uint256 amountA, address tokenB, uint256 amountB) internal pure {
        _checkAddresses(tokenA, tokenB);
        if (amountA <= 0) revert Errors.ZeroAmount();
        if (amountB <= 0) revert Errors.ZeroAmount();
    }

    function _checkMultiClaim(MultiClaim memory multiClaim, uint256 maxHops) internal pure {
        _checkAddresses(multiClaim.tokenA, multiClaim.tokenB);
        if (multiClaim.amountA <= 0) revert Errors.ZeroAmount();
        if (multiClaim.amountB <= 0) revert Errors.ZeroAmount();
        uint256 length = multiClaim.swapIds.length;
        if (length == 0 || length > maxHops) revert Errors.InvalidMultiClaimSwapCount(maxHops, length);
    }

    function _checkAddresses(address tokenA, address tokenB) internal pure {
        if (tokenA == address(0)) revert Errors.InvalidAddress();
        if (tokenB == address(0)) revert Errors.InvalidAddress();
        if (tokenA == tokenB) revert Errors.InvalidAddress();
    }

    function _checkIsValid(Swap memory swap, address sender, uint256 timestamp) internal pure {
        if (swap.maker == sender) revert Errors.ClaimOwnSwap();
        if (swap.expiration < timestamp) revert Errors.ExpiredSwap();
        if (swap.amountA <= 0) revert Errors.ZeroAmount();
        if (swap.amountB <= 0) revert Errors.ZeroAmount();
    }

    function _checkIsValueSent(uint256 sentAmount, address token, uint256 amount, uint256 fee, uint8 feeType) internal pure {
        if (fee == 0 || amount == 0) revert Errors.ZeroAmount();
        if (feeType == Constants.FEE_TYPE_ETH_FIXED) {
            if (fee != sentAmount) revert Errors.IncorrectNativeAmountSent(fee, sentAmount);
        }
        else if (token == Constants.NATIVE_ADDRESS) {
            uint256 expectedValue;
            unchecked { expectedValue = amount + fee; }
            if (expectedValue != sentAmount) revert Errors.IncorrectNativeAmountSent(expectedValue, sentAmount);
        }
        else if (sentAmount != 0) {
            revert Errors.IncorrectNativeAmountSent(0, sentAmount);
        }
    }

    function _calculateSwapA(SwapUtils.Swap memory swap, uint256 amountA, uint256 feeValue, uint256 feeDenominator, uint256 fixedFee)
    internal pure returns (SwapCalculation memory) {
        if (amountA == 0) revert Errors.ZeroAmount();
        if (amountA >= swap.amountA) {
            return _calculateCompleteSwap(swap, feeValue, feeDenominator, fixedFee);
        }
        uint256 netAmountB = MathUtils._mulDiv(swap.amountB, amountA, swap.amountA);
        return _calculateSwapNetB(swap, netAmountB, feeValue, feeDenominator, fixedFee);
    }

    function _calculateSwapGrossB(SwapUtils.Swap memory swap, uint256 grossAmountB, uint256 feeValue, uint256 feeDenominator, uint256 fixedFee)
    internal pure returns (SwapCalculation memory) {
        if (grossAmountB == 0) revert Errors.ZeroAmount();
        uint256 netAmountB;
        if (swap.feeType == Constants.FEE_TYPE_TOKEN_B) {
            netAmountB = MathUtils._mulDiv(grossAmountB, feeDenominator, (feeDenominator + feeValue));
        }
        else {
            netAmountB = grossAmountB;
        }
        return _calculateSwapNetB(swap, netAmountB, feeValue, feeDenominator, fixedFee);
    }

    function _calculateSwapNetB(SwapUtils.Swap memory swap, uint256 netAmountB, uint256 feeValue, uint256 feeDenominator, uint256 fixedFee)
    internal pure returns (SwapCalculation memory) {
        if (netAmountB == 0) revert Errors.ZeroAmount();
        if (netAmountB >= swap.amountB) {
            return _calculateCompleteSwap(swap, feeValue, feeDenominator, fixedFee);
        }
        uint256 netAmountA = MathUtils._mulDiv(swap.amountA, netAmountB, swap.amountB);
        return _calculate(swap, netAmountA, netAmountB, false, feeValue, feeDenominator, fixedFee);
    }

    function _calculateCompleteSwap(SwapUtils.Swap memory swap, uint256 feeValue, uint256 feeDenominator, uint256 fixedFee)
    internal pure returns (SwapCalculation memory) {
        return _calculate(swap, swap.amountA, swap.amountB, true, feeValue, feeDenominator, fixedFee);
    }

    function _calculate(SwapUtils.Swap memory swap, uint256 amountA, uint256 amountB, bool complete, uint256 feeValue, uint256 feeDenominator, uint256 fixedFee)
    internal pure returns (SwapCalculation memory) {
        SwapCalculation memory calculation;
        calculation.amountA = amountA;
        calculation.amountB = amountB;
        calculation.fee = FeeUtils._calculateFee(calculation.amountA, calculation.amountB, swap.feeType, feeValue, feeDenominator, fixedFee);
        calculation.feeType = swap.feeType;
        calculation.isTokenBNative = swap.tokenB == Constants.NATIVE_ADDRESS;
        calculation.isComplete = complete;
        calculation.nativeSendAmount = _calculateNativeSendAmount(calculation.amountB, calculation.fee, calculation.feeType, calculation.isTokenBNative);
        return calculation;
    }

    function _calculateNativeSendAmount(uint256 amountB, uint256 fee, uint8 feeType, bool isTokenBNative) internal pure returns (uint256) {
        if (isTokenBNative) return amountB + fee;
        if (feeType == Constants.FEE_TYPE_ETH_FIXED) return fee;
        return 0;
    }

}