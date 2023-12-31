// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ICore.sol";
import "./Dispatcher.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./CoreStructs.sol";
import "./IStargateReceiver.sol";
import "./IStargateRouter.sol";
import "./IWrappedToken.sol";
import "./FeeOperator.sol";

contract Core is ICore, FeeOperator, Dispatcher, IStargateReceiver {
    constructor(
        address _executor,
        address _stargateRouter,
        address _uniswapRouter,
        address _wrappedNative,
        address _sgETH
    ) Dispatcher(_executor, _stargateRouter, _uniswapRouter, _wrappedNative, _sgETH) {}

    /**
     * @dev Swaps currency from the incoming to the outgoing token and executes a transaction with payment.
     * @param target The address of the target contract for the payment transaction.
     * @param paymentOperator The operator address for payment transfers requiring erc20 approvals.
     * @param tokenData The token swap data and payment transaction payload
     */
    function swapAndExecute(address target, address paymentOperator, TokenData calldata tokenData)
        external
        payable
        handleFees(0, tokenData.amountIn, tokenData.tokenIn)
    {
        _receiveErc20(tokenData.amountIn, tokenData.tokenIn);
        _swapAndExecute(msg.sender, target, paymentOperator, block.timestamp, tokenData);
    }

    /**
     * @dev Bridges funds in native or erc20 and a payment transaction payload to the destination chain
     * @param lzBridgeData The configuration for the cross bridge transaction
     * @param tokenData The token swap data and payment transaction payload
     * @param lzTxObj The configuration of gas and dust for post bridge execution
     */
    function bridgeAndExecute(
        LzBridgeData calldata lzBridgeData,
        TokenData calldata tokenData,
        IStargateRouter.lzTxObj calldata lzTxObj
    ) external payable handleFees(lzBridgeData.fee, tokenData.amountIn, tokenData.tokenIn) {
        _receiveErc20(tokenData.amountIn, tokenData.tokenIn);
        address tokenIn = tokenData.tokenIn;
        if (tokenData.tokenIn == address(0)) {
            tokenIn = tokenData.tokenOut == SG_ETH ? SG_ETH : WRAPPED_NATIVE;
            IWrappedToken(tokenIn).deposit{value: tokenData.amountIn}();
        }
        // only swap if we need to
        if (tokenIn != tokenData.tokenOut) {
            _swapExactOutput(
                msg.sender, tokenIn, tokenData.amountIn, tokenData.amountOut, block.timestamp, tokenData.path
            );
        }

        if (tokenIn == tokenData.tokenOut && tokenData.amountOut > tokenData.amountIn) {
            revert BridgeOutputExceedsInput();
        }

        _approveAndBridge(tokenData.tokenOut, tokenData.amountOut, lzBridgeData, lzTxObj, tokenData.payload);
    }

    /*
     * @dev Called by the Stargate Router on the destination chain upon bridging funds.
     * @dev unused @param _srcChainId The remote chainId sending the tokens.
     * @dev unused @param _srcAddress The remote Bridge address.
     * @dev unused @param _nonce The message ordering nonce.
     * @param _token The token contract on the local chain.
     * @param amountLD The qty of local _token contract tokens.
     * @param payload The bytes containing the execution paramaters.
     */
    function sgReceive(
        uint16, // _srcChainid
        bytes memory, // _srcAddress
        uint256, // _nonce
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external override {
        if (msg.sender != address(STARGATE_ROUTER)) {
            revert OnlyStargateRouter();
        }

        (
            address sender,
            address target,
            address _paymentToken,
            address paymentOperator,
            uint256 _amountOutMin,
            bytes memory path,
            bytes memory callData
        ) = abi.decode(payload, (address, address, address, address, uint256, bytes, bytes));

        TokenData memory tokenData = TokenData(amountLD, _amountOutMin, _token, _paymentToken, path, callData);

        _swapAndExecute(sender, target, paymentOperator, block.timestamp, tokenData);

        emit ReceivedOnDestination(_token, amountLD);
    }

    function withdraw(IERC20 token) external onlyOwner {
        SafeERC20.safeTransfer(token, msg.sender, token.balanceOf(address(this)));
    }

    function withdrawEth() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Could not drain ETH");
    }

    /// @notice To receive ETH from WETH and NFT protocols
    receive() external payable {}
}
