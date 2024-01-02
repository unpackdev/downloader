// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
pragma abicoder v2;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ISwapRouter02.sol";

import "./IWETH.sol";
interface ISwapRouter2 is ISwapRouter02 {
    function refundETH() external payable;
}

/**
 * @title UniswapV3Proxy
 * @notice this contract is a proxy contract to uniswapV3 router contract
 * @notice token to token swap is not supported
 * @dev the proxy contract method names matches exactly with uniswapV3 contract to make integration simpler
 * @dev the swap methods take extra parameters along with original params such as feePercentage
 * @dev feePercentage is represented as 1% = 100
 */

contract UniswapV3ProxyDegen is Ownable {
    using SafeERC20 for IERC20;
    address public immutable router;
    address public immutable weth;
    address public feeReceiver;

    event SetFeeReceiver(address indexed oldFeeReceiver, address indexed newFeeReceiver);

    constructor(address _router, address _weth, address _feeReceiver) {
        require(_router != address(0), "Invalid Address");
        require(_weth != address(0), "Invalid Address");
        router = _router;
        weth = _weth;
        feeReceiver = _feeReceiver;
    }

    /**
     * @notice set new feeReceiver address
     */
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        emit SetFeeReceiver(feeReceiver, _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    function exactInputSingle(
        ISwapRouter2.ExactInputSingleParams memory params,
        uint256 feePercentage
    )external payable {
        // either tokenIn or tokenOut must be ETH
        if (msg.value > 0) {
            require(params.tokenIn == weth, "UniswapV3Proxy: INVALID_TOKEN_IN");
            // deduct fee from amountIn
            _beforeETHSwap(feePercentage);
            // set amountIn after deducting fee
            uint256 ethToSend = address(this).balance;
            params.amountIn = ethToSend;
            // swap on uniswap router
            ISwapRouter2(router).exactInputSingle{ value: ethToSend }(params);
            // refund unspent ETH
            _refundUnspentETH();
        } else {
            require(params.tokenOut == weth, "UniswapV3Proxy: INVALID_TOKEN_OUT");
            // transfer erc20 from user to proxy contract
            _beforeTokenSwap(params.tokenIn, params.amountIn);
            // set recipient to proxy contract. the received ETH will be sent to this address
            address to = params.recipient;
            params.recipient = address(this);
            // swap on uniswap router
            ISwapRouter2(router).exactInputSingle(params);
            // send the received ETH to the receiver and send the fee amount to feeReceiver
            _handlePostETHReceive(to, feePercentage);
        }
    }

    function exactInput(
        address tokenIn,
        address tokenOut,
        ISwapRouter2.ExactInputParams memory params,
        uint256 feePercentage
    )external payable {
        if (msg.value > 0) {
            require(tokenIn == weth, "UniswapV3Proxy: INVALID_TOKEN_IN");
            _beforeETHSwap(feePercentage);
            uint256 ethToSend = address(this).balance;
            params.amountIn = ethToSend;
            // swap on uniswap router
            ISwapRouter2(router).exactInput{ value: ethToSend }(params);
            _refundUnspentETH();
        } else {
            require(tokenOut == weth, "UniswapV3Proxy: INVALID_TOKEN_OUT");
            _beforeTokenSwap(tokenIn, params.amountIn);
            address to = params.recipient;
            params.recipient = address(this);
            // swap on uniswap router
            ISwapRouter2(router).exactInput(params);
            _handlePostETHReceive(to, feePercentage);
        }
    }

    function exactOutputSingle(
        ISwapRouter2.ExactOutputSingleParams memory params,
        uint256 feePercentage
    )external payable {
        if (msg.value > 0) {
            require(params.tokenIn == weth, "UniswapV3Proxy: INVALID_TOKEN_IN");
            _beforeETHSwap(feePercentage);
            uint256 ethToSend = address(this).balance;
            params.amountInMaximum = ethToSend;
            // swap on uniswap router
            ISwapRouter2(router).exactOutputSingle{ value: ethToSend }(params);
            _refundUnspentETH();
        } else {
            require(params.tokenOut == weth, "UniswapV3Proxy: INVALID_TOKEN_OUT");
            _beforeTokenSwap(params.tokenIn, params.amountInMaximum);
            address to = params.recipient;
            params.recipient = address(this);
            // swap on uniswap router
            ISwapRouter2(router).exactOutputSingle(params);
            _handlePostETHReceive(to, feePercentage);
            _refundRemainingTokens(params.tokenIn);
        }
    }

    function exactOutput(
        address tokenIn,
        address tokenOut,
        ISwapRouter2.ExactOutputParams memory params,
        uint256 feePercentage
    )external payable {
        if (msg.value > 0) {
            require(tokenIn == weth, "UniswapV3Proxy: INVALID_TOKEN_IN");
            _beforeETHSwap(feePercentage);
            uint256 ethToSend = address(this).balance;
            params.amountInMaximum = ethToSend;
            // swap on uniswap router
            ISwapRouter2(router).exactOutput{ value: ethToSend }(params);
            _refundUnspentETH();
        } else {
            require(tokenOut == weth, "UniswapV3Proxy: INVALID_TOKEN_OUT");
            _beforeTokenSwap(tokenIn, params.amountInMaximum);
            address to = params.recipient;
            params.recipient = address(this);
            // swap on uniswap router
            ISwapRouter2(router).exactOutput(params);
            _handlePostETHReceive(to, feePercentage);
            _refundRemainingTokens(tokenIn);
        }
    }

    /**
     * @notice preprocessing before token swap on uniswap
     * @dev fetch the fromToken amount from user and approves to spend on uniswap
     * @param token fromToken address
     * @param amountIn amount to swap
     */
    function _beforeTokenSwap(address token, uint amountIn) internal {
        // transfer erc20 from user to proxy contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
        // approve token to spend on behalf of proxy contract
        IERC20(token).approve(router, amountIn);
    }
    function _beforeETHSwap(uint256 feePercentage) internal {
        uint256 feeAmount;
        // send platform fee to receiver address
        if (feeReceiver != address(0) && feePercentage > 0) {
            feeAmount = (msg.value * feePercentage) / 100_00;
            payable(feeReceiver).transfer(feeAmount);
        }
    }
    /**
     * @notice post processing after token swap on uniswap
     * @dev sends feeAmount to receiver and sends back sender the remaining balance of amountIn after swap
     * @param token fromToken address
     */
    function _refundRemainingTokens(address token) internal {
        // Refund remaining amount to msg.sender
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(msg.sender, balance);
        }
    }

    // refund remaining ETH to msg.sender
    function _refundUnspentETH() internal {
        // retrieve remaining ETH from router
        ISwapRouter2(router).refundETH();
        // transfer remaining ETH from amountIn to msg.sender
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @notice post processing after token swap to eth
     * @dev deduct the feeAmount and send remaining eth to receiver
     */
    function _handlePostETHReceive(address to,  uint256 feePercentage) internal {
        // convert weth to eth
        IWETH(weth).withdraw(IERC20(weth).balanceOf(address(this)));
        // send the received ETH to the receiver and send the fee amount to feeReceiver
        uint256 ethReceived = address(this).balance;
        uint256 feeAmount;
        if (feeReceiver != address(0) && feePercentage > 0) {
            feeAmount = (ethReceived * feePercentage) / 100_00;
            payable(feeReceiver).transfer(feeAmount);
        }
        payable(to).transfer(ethReceived - feeAmount);
    }
    receive() external payable {}
}
