// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibSwap.sol";
import "./LibAsset.sol";
import "./LibAllowList.sol";
import "./LibUtil.sol";
import "./GenericErrors.sol";
import "./IWETH.sol";
import "./LibFeeCollector.sol";
import "./GenericErrors.sol";

/// @title Swapper
/// @author FormalCrypto
/// @notice Contract that provides swap functionality
contract Swapper {
    /**
     * @dev Deposits swaps, executes swaps and perform minimum amount check 
     * @param _fromAmount Amount of tokens to be swapped
     * @param _minAmount Minimum amount of last token to receive
     * @param _weth Address of wrapped native asset(used when swapping native asset)
     * @param _swaps Array of data used to execute swaps
     * @param _nativeReserve Amout of native asset to prevent from being swapped
     * @param _partner Partner address
     */
    function _swap(
        uint256 _fromAmount,
        uint256 _minAmount,
        address _weth,
        LibSwap.SwapData[] calldata _swaps,
        uint256 _nativeReserve,
        address _partner
    ) internal returns (uint256) {
        uint256 numSwaps = _swaps.length;
        uint256 fromAmount = _fromAmount;
        address fromToken = _swaps[0].fromToken;

        if (numSwaps == 0) revert EmptySwapPath();

        address lastToken = _swaps[numSwaps - 1].toToken;
        uint256 initialBalance = LibAsset.getOwnBalance(lastToken);

        if (LibAsset.isNativeAsset(lastToken)) {
            initialBalance -= msg.value;
        }

        if (LibAsset.isNativeAsset(fromToken)) {
            if (LibUtil.isZeroAddress(_weth)) revert IncorrectWETH();
            if (fromAmount + _nativeReserve != msg.value) revert IncorrectMsgValue();
            IWETH(_weth).deposit{value: fromAmount}();
            fromToken = _weth;
        } else {
            LibAsset.depositAsset(fromToken, fromAmount);
        }

        fromAmount = LibFeeCollector.takeFromTokenFee(fromAmount, fromToken, _partner);

        _executeSwaps(_swaps, fromAmount, _weth);

        uint256 receivedAmount;
        if (LibAsset.isNativeAsset(lastToken)) {
            receivedAmount = LibAsset.getOwnBalance(_weth) - initialBalance;
            IWETH(_weth).withdraw(receivedAmount);
        } else {
            receivedAmount = LibAsset.getOwnBalance(lastToken) - initialBalance; 
        }

        if (receivedAmount < _minAmount) revert CumulativeSlippageTooHigh(_minAmount, receivedAmount);

        return receivedAmount;
    }

    /**
     * @dev Executes swaps and checks that adapter is whitelisted
     * @param _swaps Array of data used to execute swaps    
     * @param _fromAmount Amount of tokens to be swapped
     * @param _weth Address of wrapped native asset(used when swapping native asset)
     */
    function _executeSwaps(LibSwap.SwapData[] calldata _swaps, uint256 _fromAmount, address _weth) internal {
        uint256 numSwaps = _swaps.length;
        uint256 receivedAmount;
        for (uint256 i = 0; i < numSwaps; ) {
            LibSwap.SwapData calldata currentSwap = _swaps[i];

            if (
                !((LibAsset.isNativeAsset(currentSwap.fromToken) ||
                    LibAllowList.isContractAllowed(currentSwap.adapter)) &&
                    LibAllowList.isContractAllowed(currentSwap.adapter)
                )
            ) revert ContractCallNotAllowed();

            
            uint256 fromAmount = i > 0 
                ? receivedAmount
                : _fromAmount;

            receivedAmount = LibSwap.swap(
                fromAmount,
                currentSwap,
                _weth
            );

            unchecked {
                ++i;
            }
        }
    }
}