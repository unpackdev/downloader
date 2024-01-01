// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Maintainable.sol";
import "./AvabotAdapter.sol";

abstract contract AvabotFeeOnTransferAdapter is AvabotAdapter {
    function swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _fromToken,
        address _toToken,
        address _to
    ) external override virtual {
        _swap(_amountIn, _amountOut, _fromToken, _toToken, _to);
        emit AvabotAdapterSwap(_fromToken, _toToken, _amountIn, _amountOut);
    }
}
