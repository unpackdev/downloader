// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";

/**
 * @title UniswapProxy
 * @notice A universal proxy contract to uniswapv2 based swap contracts. This contract routes user requests to uniswap contract addresss with additional capability such as fee processing.
 */

contract UniswapV2ProxyDegen is Ownable {
    using SafeERC20 for IERC20;
    address public feeReceiver;

    event SetFeeReceiver(address indexed oldFeeReceiver, address indexed newFeeReceiver);

    /**
     * @notice ensures that the deadline is not exceeding block timestamp
     */
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        _;
    }

    constructor(address _feeReceiver) {
        feeReceiver = _feeReceiver;
    }

    /**
     * @notice set new feeReceiver address
     */
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        emit SetFeeReceiver(feeReceiver, _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    function swapExactETHForTokens(
        address router,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feePercetage
    ) external payable ensure(deadline) {
        _beforeETHSwap(feePercetage);
        //swap
        IUniswapV2Router02(router).swapExactETHForTokens{value: address(this).balance}(
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address router,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feePercetage
    ) external payable ensure(deadline) {
        _beforeETHSwap(feePercetage);
        //swap
        IUniswapV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: address(this).balance
        }(amountOutMin, path, to, deadline);
    }

    /**
     * @notice swaps ETH(native blockchain currency) to dest token address
     * @dev available amount to swap = msg.value - feeAmount
     */
    function swapETHForExactTokens(
        address router,
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feePercetage
    ) external payable ensure(deadline) {
        _beforeETHSwap(feePercetage);
        //swap
        IUniswapV2Router02(router).swapETHForExactTokens{value: address(this).balance}(
            amountOut,
            path,
            to,
            deadline
        );
        _refundRemainingETH();
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feePercentage
    ) external ensure(deadline) {
        address fromToken = path[0];
        _beforeTokenSwap(router, fromToken, amountIn);
        // swap Token and receive the ETH amount to this contract 
        IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        _handlePostETHReceive(to, feePercentage);
    }

    function swapTokensForExactETH(
        address router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feePercentage
    ) external {
        address fromToken = path[0];
        _beforeTokenSwap(router, fromToken, amountInMax);
        // swap Token and receive the ETH amount to this contract 
        IUniswapV2Router02(router).swapTokensForExactETH(amountOut, amountInMax, path, address(this), deadline);
        _handlePostETHReceive(to, feePercentage);
        _refundRemainingTokens(fromToken);
    }

    function swapExactTokensForETH(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feePercentage
    ) external ensure(deadline) {
        address fromToken = path[0];
        _beforeTokenSwap(router, fromToken, amountIn);
        // swap Token and receive the ETH amount to this contract 
        IUniswapV2Router02(router).swapExactTokensForETH(amountIn, amountOutMin, path, address(this), deadline);
        _handlePostETHReceive(to, feePercentage);
    }

    /**
     * @notice preprocessing before token swap on uniswap
     * @dev fetch the fromToken amount from user and approves to spend on uniswap
     * @param router uniswap router address
     * @param token fromToken address
     * @param amountIn amount to swap
     */
    function _beforeTokenSwap(address router, address token, uint amountIn) internal {
        // transfer erc20 from user to proxy contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
        // approve token to spend on behalf of proxy contract
        IERC20(token).approve(address(router), amountIn);
    }

    function _beforeETHSwap(uint256 feePercetage) internal {
        // send platform fee to receiver address
        if (feeReceiver != address(0) && feePercetage > 0) {
            uint256 feeAmount = (msg.value * feePercetage) / 100_00;
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

    function _refundRemainingETH() internal {
        // refund the remaining ETH after swap to the user
        uint256 refundEthAmount = address(this).balance;
        if (refundEthAmount > 0) {
            payable(msg.sender).transfer(refundEthAmount);
        }
    }
    function _handlePostETHReceive(address to,  uint256 feePercentage) internal {
        // send the received ETH to the receiver and send the fee amount to feeReceiver
        uint256 ethReceived = address(this).balance;
        if (ethReceived > 0) {
            uint256 feeAmount;
            if (feeReceiver != address(0) && feePercentage > 0) {
                feeAmount = (ethReceived * feePercentage) / 100_00;
                payable(feeReceiver).transfer(feeAmount);
            }
            payable(to).transfer(ethReceived - feeAmount);
        }
    }

    receive() external payable {}
}
