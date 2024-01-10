// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "./IHandler.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./TokenUtils.sol";
import "./Tokens.sol";
import "./IWETH.sol";
import "./FUniswapV2.sol";
import "./FLimitOrders.sol";
import "./FHandlerUtils.sol";

/// @notice UniswapV2 Handler used to execute an order via UniswapV2Router02
/// @dev This does NOT implement the standard IHANDLER
contract UniswapV2Router02Handler is IHandler {
    using TokenUtils for address;

    // solhint-disable var-name-mixedcase
    address public UNI_ROUTER;
    address public immutable WRAPPED_NATIVE;

    // solhint-enable var-name-mixedcase

    constructor(address _uniRouter, address _wrappedNative) {
        UNI_ROUTER = _uniRouter;
        WRAPPED_NATIVE = _wrappedNative;
    }

    /// @notice receive ETH from UniV2Router02 during swapXForEth
    receive() external payable override {
        require(
            msg.sender != tx.origin,
            "UniswapV2Router02Handler#receive: NO_SEND_NATIVE_PLEASE"
        );
    }

    /**
     * @notice Handle an order execution
     * @param _inToken - Address of the input token
     * @param _outToken - Address of the output token
     * @param _amountOutMin - Address of the output token
     * @param _data - (module, relayer, fee, intermediatePath, intermediateFeePath)
     * @return bought - Amount of output token bought
     */
    // solhint-disable-next-line function-max-lines
    function handle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256,
        uint256 _amountOutMin,
        bytes calldata _data
    ) external virtual override returns (uint256 bought) {
        (
            uint256 amountIn,
            address[] memory path,
            address relayer,
            uint256 fee,
            address[] memory feePath
        ) = _handleInputData(
                address(this),
                address(_inToken),
                address(_outToken),
                _data
            );

        // Swap and charge fee in ETH
        if (
            address(_inToken) == WRAPPED_NATIVE || address(_inToken) == NATIVE
        ) {
            if (address(_inToken) == WRAPPED_NATIVE)
                IWETH(WRAPPED_NATIVE).withdraw(fee);
            bought = _swap(amountIn - fee, _amountOutMin, path, msg.sender);
        } else if (
            address(_outToken) == WRAPPED_NATIVE || address(_outToken) == NATIVE
        ) {
            bought = _swap(amountIn, _amountOutMin + fee, path, address(this));
            if (address(_outToken) == WRAPPED_NATIVE)
                IWETH(WRAPPED_NATIVE).withdraw(fee);
            address(_outToken).transfer(msg.sender, bought - fee);
        } else {
            uint256 feeAmountIn = _swapTokensForExactETH(
                IUniswapV2Router02(UNI_ROUTER),
                fee, // amountOut (in ETH)
                amountIn, // amountInMax (in inputToken)
                feePath,
                address(this),
                block.timestamp + 1 // solhint-disable-line not-rely-on-time
            );
            _swap(amountIn - feeAmountIn, _amountOutMin, path, msg.sender);
        }

        // Send fee to relayer
        (bool successRelayer, ) = relayer.call{value: fee}("");
        require(
            successRelayer,
            "UniswapV2Router02Handler#handle: TRANSFER_NATIVE_TO_RELAYER_FAILED"
        );
    }

    /**
     * @notice Check whether can handle an order execution
     * @param _inToken - Address of the input token
     * @param _outToken - Address of the output token
     * @param _amountIn - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - (module, relayer, fee, intermediatePath)
     * @return bool - Whether the execution can be handled or not
     */
    // solhint-disable-next-line code-complexity
    function canHandle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256 _amountIn,
        uint256 _minReturn,
        bytes calldata _data
    ) external view virtual override returns (bool) {
        return
            _canHandleLimitOrder(
                address(this),
                address(_inToken),
                address(_outToken),
                _amountIn,
                _minReturn,
                UNI_ROUTER,
                WRAPPED_NATIVE,
                _data
            );
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _recipient
    ) internal virtual returns (uint256 bought) {
        bought = _swapExactXForX(
            WRAPPED_NATIVE,
            IUniswapV2Router02(UNI_ROUTER),
            _amountIn,
            _amountOutMin,
            _path,
            _recipient,
            block.timestamp + 1 // solhint-disable-line not-rely-on-time
        );
    }
}
