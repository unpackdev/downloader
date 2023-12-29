// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IUniswapV2Router02.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Counters.sol";
import "./IUniswapV2Factory.sol";

// for debug
//import  "hardhat/console.sol";

contract ETHSwapper is Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapRouter;
    address public weth;

    constructor(address _router, address _weth) {
        uniswapRouter = IUniswapV2Router02(_router);
        weth = _weth;
    }

    function buyToken(address tokenAddress, uint256 slippage) external payable {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = tokenAddress;

        // Calculate amounts out
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(msg.value, path);

        // Calculate the minimum amount to receive after slippage
        uint256 amountOutMin = (amountsOut[1] * (100 - slippage)) / 100;

        // Make the swap
        uniswapRouter.swapExactETHForTokens{ value: msg.value }(
            amountOutMin,
            path,
            msg.sender,
            block.timestamp + 60 * 5
        );
    }

    function sellToken(
        address tokenAddress,
        uint256 percentToSell,
        uint256 slippage
    ) external {
        require(percentToSell <= 100, "Invalid percentage: Must be 0-100");
        require(slippage <= 100, "Invalid slippage: Must be 0-100");

        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(msg.sender);
        require(balance > 0, "Nothing to sell: Insufficient balance");

        uint256 amountToSell = (balance * percentToSell) / 100;

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapRouter.WETH();

        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(amountToSell, path);
        uint256 amountOut = amountsOut[1];
        uint256 amountOutMin = (amountOut * (10000 - slippage * 100)) / 10000;

        token.approve(address(uniswapRouter), amountToSell);

        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToSell,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp + 60 * 5
        );
    }

}
