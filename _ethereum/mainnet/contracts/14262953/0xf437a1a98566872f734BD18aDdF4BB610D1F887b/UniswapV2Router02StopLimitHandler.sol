// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./UniswapV2Router02Handler.sol";
import "./FStopLimitOrders.sol";

/// @notice UniswapV2 Handler used to execute an order via UniswapV2Router02
/// @dev This does NOT implement the standard IHANDLER
contract UniswapV2Router02StopLimitHandler is UniswapV2Router02Handler {
    constructor(address _uniRouter, address _wrappedNative)
        UniswapV2Router02Handler(_uniRouter, _wrappedNative)
    {} // solhint-disable-line no-empty-blocks

    function canHandle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256 _amountIn,
        uint256 _minReturn,
        bytes calldata _data
    ) external view override returns (bool) {
        return
            _canHandleStopLimitOrder(
                address(_inToken),
                address(_outToken),
                _amountIn,
                _minReturn,
                UNI_ROUTER,
                WRAPPED_NATIVE,
                _data
            );
    }
}
