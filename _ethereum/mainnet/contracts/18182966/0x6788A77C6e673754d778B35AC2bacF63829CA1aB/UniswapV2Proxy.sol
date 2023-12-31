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

contract UniswapV2Proxy is Ownable {
    using SafeERC20 for IERC20;
    address public feeReceiver;

    event SetFeeReceiver(address indexed oldFeeReceiver, address indexed newFeeReceiver);
    event RecoverETH(address indexed receiver, uint256 amount);
    event RecoverERC20(address indexed receiver, address indexed tokenAddress,  uint256 amount);

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

    /**
     * @notice routes the call to uniswap's swapExactTokensForTokens method
     * @dev except the params router, feeAmount and feeReceiver, all the params are same as uniswap and the structure follows to all the remaining functions
     * @param router uniswap router address
     * @param feeAmount feeAmount in the units of fromToken
     */
    function swapExactTokensForTokens(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feeAmount
    ) external ensure(deadline) {
        address fromToken = path[0];
        _beforeTokenSwap(router, fromToken, amountIn, feeAmount);
        //swap
        IUniswapV2Router02(router).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
        _afterTokenSwap(fromToken, feeAmount);
    }

    function swapTokensForExactTokens(
        address router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feeAmount
    ) external ensure(deadline) {
        address fromToken = path[0];
        _beforeTokenSwap(router, fromToken, amountInMax, feeAmount);
        IUniswapV2Router02(router).swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
        _afterTokenSwap(fromToken, feeAmount);
    }

    function swapExactETHForTokens(
        address router,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feeAmount
    ) external payable ensure(deadline) {
        // transfer the feeAmount to receiver first, rest amount is available for swap
        require(msg.value > feeAmount, "insufficient amount");
        // send platform fee to receiver address
        if (feeReceiver != address(0) && feeAmount > 0) {
            payable(feeReceiver).transfer(feeAmount);
        }
        //swap
        IUniswapV2Router02(router).swapExactETHForTokens{value: address(this).balance}(
            amountOutMin,
            path,
            to,
            deadline
        );
        uint256 refundEthAmount = address(this).balance;
        if (refundEthAmount > 0) {
            payable(msg.sender).transfer(refundEthAmount);
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feeAmount
    ) external ensure(deadline) {
        address fromToken = path[0];
        _beforeTokenSwap(router, fromToken, amountIn, feeAmount);
        //swap
        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        _afterTokenSwap(fromToken, feeAmount);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address router,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feeAmount
    ) external payable ensure(deadline) {
        // transfer the feeAmount to receiver first, rest amount is available for swap
        require(msg.value > feeAmount, "insufficient amount");
        // send platform fee to receiver address
        if (feeReceiver != address(0) && feeAmount > 0) {
            payable(feeReceiver).transfer(feeAmount);
        }
        //swap
        IUniswapV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: address(this).balance
        }(amountOutMin, path, to, deadline);
        uint256 refundEthAmount = address(this).balance;
        if (refundEthAmount > 0) {
            payable(msg.sender).transfer(refundEthAmount);
        }
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feeAmount
    ) external ensure(deadline) {
        address fromToken = path[0];
        _beforeTokenSwap(router, fromToken, amountIn, feeAmount);
        //swap
        IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        _afterTokenSwap(fromToken, feeAmount);
    }

    function swapTokensForExactETH(
        address router,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feeAmount
    ) external {
        address fromToken = path[0];
        _beforeTokenSwap(router, fromToken, amountInMax, feeAmount);
        IUniswapV2Router02(router).swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
        _afterTokenSwap(fromToken, feeAmount);
    }

    function swapExactTokensForETH(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 feeAmount
    ) external ensure(deadline) {
        address fromToken = path[0];
        _beforeTokenSwap(router, fromToken, amountIn, feeAmount);
        IUniswapV2Router02(router).swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
        _afterTokenSwap(fromToken, feeAmount);
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
        uint256 feeAmount
    ) external payable ensure(deadline) {
        // transfer the feeAmount to receiver first, rest amount is available for swap
        require(msg.value > feeAmount, "insufficient amount");
        // send platform fee to receiver address
        if (feeReceiver != address(0) && feeAmount > 0) {
            payable(feeReceiver).transfer(feeAmount);
        }
        //swap
        IUniswapV2Router02(router).swapETHForExactTokens{value: address(this).balance}(
            amountOut,
            path,
            to,
            deadline
        );
        // refund the remaining ETH after swap to the user
        uint256 refundEthAmount = address(this).balance;
        if (refundEthAmount > 0) {
            payable(msg.sender).transfer(refundEthAmount);
        }
    }

    /**
     * @notice preprocessing before token swap on uniswap
     * @dev fetch the fromToken amount from user and approves to spend on uniswap
     * @param router uniswap router address
     * @param token fromToken address
     * @param amountIn amount to swap
     * @param feeAmount platform fees in fromToken units
     */
    function _beforeTokenSwap(address router, address token, uint amountIn, uint256 feeAmount) internal {
        // transfer erc20 from user to proxy contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn + feeAmount);
        // approve token to spend on behalf of proxy contract
        IERC20(token).approve(address(router), amountIn);
    }

    /**
     * @notice post processing after token swap on uniswap
     * @dev sends feeAmount to receiver and sends back sender the remaining balance of amountIn after swap
     * @param token fromToken address
     * @param feeAmount platform fees in fromToken units
     */
    function _afterTokenSwap(address token, uint256 feeAmount) internal {
        // return fees to feeCollector
        if (feeReceiver != address(0) && feeAmount > 0) {
            IERC20(token).safeTransfer(feeReceiver, feeAmount);
        }
        // Refund remaining amount to msg.sender
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(msg.sender, balance);
        }
    }

    /**
     * @notice recover accidently sent ERC20 tokens to the contract
     * @param tokenAddress address of the erc20 token contract
     */
    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(msg.sender, balance);
        }
        emit RecoverERC20(msg.sender, tokenAddress, balance);
    }

    /**
     * @notice recover accidently sent ETH to the contract
     */
    function recoverETH() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
        emit RecoverETH(msg.sender, balance);
    }

    receive() external payable {}
}
