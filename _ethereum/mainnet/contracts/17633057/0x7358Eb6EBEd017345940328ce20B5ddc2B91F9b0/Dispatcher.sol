// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./BoxImmutables.sol";
import "./IWrappedToken.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ISwapRouter.sol";
import "./SafeERC20.sol";
import "./CoreStructs.sol";
import "./IStargateRouter.sol";
import "./IExecutor.sol";

contract Dispatcher is BoxImmutables, Ownable {
    constructor(
        address _executor,
        address _stargateRouter,
        address _uniswapRouter,
        address _wrappedNative,
        address _sgEth
    ) BoxImmutables(_executor, _stargateRouter, _uniswapRouter, _wrappedNative, _sgEth) {}

    /**
     * @dev Internal function to handle receiving erc20 tokens for bridging and swapping.
     * @param amountIn The amount of native or erc20 being transferred.
     * @param tokenIn The address of the token being transferred.
     */
    function _receiveErc20(uint256 amountIn, address tokenIn) internal {
        if (tokenIn != address(0)) {
            SafeERC20.safeTransferFrom(IERC20(tokenIn), msg.sender, address(this), amountIn);
        }
    }

    event BridgedExecutionUnsuccessful();

    event RefundUnsuccessful();

    error ExecutionUnsuccessful();

    error SwapOutputExceedsInput();

    error BridgeOutputExceedsInput();

    /**
     * @dev Internal function to approve an erc20 token and perform a cross chain swap using Stargate Router.
     * @param bridgeToken The erc20 which will be approved and transferred.
     * @param amountOut The amount of bridge token being transferred.
     * @param lzBridgeData The configuration for the cross bridge transaction.
     * @param lzTxObj The configuration of gas and dust for post bridge execution.
     * @param payload The bytes containing execution parameters for post bridge execution.
     */
    function _approveAndBridge(
        address bridgeToken,
        uint256 amountOut,
        LzBridgeData calldata lzBridgeData,
        IStargateRouter.lzTxObj calldata lzTxObj,
        bytes calldata payload
    ) internal {
        // approve for bridge
        SafeERC20.safeIncreaseAllowance(IERC20(bridgeToken), STARGATE_ROUTER, amountOut);
        IStargateRouter(STARGATE_ROUTER).swap{value: lzBridgeData.fee}(
            lzBridgeData._dstChainId, // send to LayerZero chainId
            lzBridgeData._srcPoolId, // source pool id
            lzBridgeData._dstPoolId, // dst pool id
            payable(msg.sender), // refund adddress. extra gas (if any) is returned to this address
            amountOut, // quantity to swap
            (amountOut * 994) / 1000, // the min qty you would accept on the destination, fee is 6 bips
            lzTxObj, // additional gasLimit increase, airdrop, at address
            abi.encodePacked(lzBridgeData._bridgeAddress), // the address to send the tokens to on the destination
            payload // bytes param, if you wish to send additional payload you can abi.encode() them here
        );
    }

    /**
     * @dev Internal function to swap tokens for an exact output amount using Uniswap v3 SwapRouter.
     * @param sender The account receiving any refunds, typically the EOA which initiated the transaction.
     * @param tokenIn The input token for the swap, use zero address to convert native to erc20 wrapped native.
     * @param amountInMaximum The maximum amount allocated to swap for the exact amount out.
     * @param amountOut The exact output amount of tokens desired from the swap.
     * @param deadline The deadline for execution of the Uniswap transaction.
     * @param path The encoded sequences of pools and fees required to perform the swap.
     */
    function _swapExactOutput(
        address sender,
        address tokenIn,
        uint256 amountInMaximum,
        uint256 amountOut,
        uint256 deadline,
        bytes memory path
    ) internal returns (bool success) {
        // deposit native into wrapped native if necessary
        if (tokenIn == address(0)) {
            IWrappedToken(WRAPPED_NATIVE).deposit{value: amountInMaximum}();
            tokenIn = WRAPPED_NATIVE;
        }

        // approve router to use our wrapped native
        SafeERC20.safeIncreaseAllowance(IERC20(tokenIn), UNISWAP_ROUTER, amountInMaximum);

        // setup the parameters for multi hop swap
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: path,
            recipient: address(this),
            deadline: deadline,
            amountOut: amountOut,
            amountInMaximum: amountInMaximum
        });

        success = true;
        uint256 refund;

        // perform the swap and calculate any excess erc20 funds
        if (msg.sender == STARGATE_ROUTER) {
            try ISwapRouter(UNISWAP_ROUTER).exactOutput(params) returns (uint256 amountIn) {
                refund = amountInMaximum - amountIn;
            } catch {
                refund = amountInMaximum;
                success = false;
            }
        } else {
            uint256 amountIn = ISwapRouter(UNISWAP_ROUTER).exactOutput(params);
            refund = amountInMaximum - amountIn;
        }

        // refund any excess erc20 funds to sender
        if (refund > 0) {
            SafeERC20.safeDecreaseAllowance(IERC20(tokenIn), UNISWAP_ROUTER, refund);
            SafeERC20.safeTransfer(IERC20(tokenIn), sender, refund);
        }
    }

    /**
     * @dev Internal function to swaps currency from the incoming to the outgoing token and execute a transaction with payment.
     * @param sender The account receiving any refunds, typically the EOA which initiated the transaction.
     * @param target The address of the target contract for the payment transaction.
     * @param paymentOperator The operator address for payment transfers requiring erc20 approvals.
     * @param deadline The deadline for execution of the uniswap transaction.
     * @param data The token swap data and post bridge execution payload.
     */
    function _swapAndExecute(
        address sender,
        address target,
        address paymentOperator,
        uint256 deadline,
        TokenData memory data
    ) internal {
        bool success = true;

        // confirm native currency output does not exceed native currency input
        if (data.tokenIn == data.tokenOut && data.amountOut > data.amountIn) {
            if (msg.sender == STARGATE_ROUTER) {
                _refund(sender, data.tokenIn, data.amountIn);
                success = false;
            } else {
                revert SwapOutputExceedsInput();
            }
        }

        // if necessary, swap incoming and outgoing tokens and unwrap native funds
        if (data.tokenIn != data.tokenOut) {
            if (data.tokenIn == WRAPPED_NATIVE && data.tokenOut == address(0)) {
                // unwrap native funds
                IWrappedToken(WRAPPED_NATIVE).withdraw(data.amountOut);
            } else if (data.tokenIn != SG_ETH || data.tokenOut != address(0)) {
                success = _swapExactOutput(sender, data.tokenIn, data.amountIn, data.amountOut, deadline, data.path);

                if (data.tokenOut == address(0)) {
                    IWrappedToken(WRAPPED_NATIVE).withdraw(data.amountOut);
                }
            }
        }

        if (success) {
            if (data.tokenOut == address(0)) {
                // complete payment transaction with native currency
                try IExecutor(EXECUTOR).execute{value: data.amountOut}(target, paymentOperator, data) returns (
                    bool executionSuccess
                ) {
                    success = executionSuccess;
                } catch {
                    success = false;
                }
            } else {
                // complete payment transaction with erc20 using executor
                SafeERC20.safeIncreaseAllowance(IERC20(data.tokenOut), EXECUTOR, data.amountOut);
                try IExecutor(EXECUTOR).execute(target, paymentOperator, data) returns (bool executionSuccess) {
                    success = executionSuccess;
                } catch {
                    success = false;
                }
            }

            if (!success) {
                if (msg.sender == STARGATE_ROUTER) {
                    _refund(sender, data.tokenOut, data.amountOut);
                    emit BridgedExecutionUnsuccessful();
                } else {
                    revert ExecutionUnsuccessful();
                }
            }
        }
    }

    /**
     * @dev Internal function to handle refund transfers of native or erc20 to a recipient.
     * @param to The recipient of the refund transfer.
     * @param token The token being transferred, use zero address for native currency.
     * @param amount The amount of native or erc20 being transferred to the recipient.
     */
    function _refund(address to, address token, uint256 amount) internal {
        if (token == address(0)) {
            (bool success,) = payable(to).call{value: amount}("");
            if (!success) {
                emit RefundUnsuccessful();
            }
        } else {
            SafeERC20.safeTransfer(IERC20(token), to, amount);
        }
    }
}
