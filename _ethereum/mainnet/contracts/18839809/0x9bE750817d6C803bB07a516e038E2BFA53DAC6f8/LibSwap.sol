// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibAsset.sol";
import "./LibUtil.sol";
import "./GenericErrors.sol";
import "./IERC20.sol";
import "./IAdapter.sol";

/// @title Lib Swap
/// @author FormalCrypto
/// @notice Provides functionality to swap tokens
library LibSwap {
    event AssetSwapped(
        address dex,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 timestamp
    );

    struct SwapData {
        address fromToken;
        address toToken;
        address adapter;
        IAdapter.Route route;
    }

    function swap(uint256 _fromAmount, SwapData calldata _swap, address _weth) internal returns (uint256 receivedAmount) {
        if (_fromAmount == 0) revert NoSwapFromZeroBalance();

        uint256 initialReceivingAssetBalance = LibAsset.getOwnBalance(
            _swap.toToken
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory res) = _swap.adapter.delegatecall(
            abi.encodeWithSelector(
                IAdapter.swap.selector,
                LibAsset.isNativeAsset(_swap.fromToken) ? _weth : _swap.fromToken,
                address(0),
                _fromAmount,
                _swap.route
            )
        );
        if (!success) {
            string memory reason = LibUtil.getRevertMsg(res);
            revert(reason);
        }

        uint256 newBalance = LibAsset.getOwnBalance(_swap.toToken);
        
        receivedAmount = newBalance - initialReceivingAssetBalance;

        emit AssetSwapped(
            _swap.adapter,
            _swap.fromToken,
            _swap.toToken,
            _fromAmount,
            newBalance > initialReceivingAssetBalance
                ? newBalance - initialReceivingAssetBalance
                : newBalance,
            block.timestamp
        );
    }
}
