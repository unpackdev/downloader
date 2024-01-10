// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.3;

import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract SellContract {
    address internal constant UNISWAP_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Router02 public uniswapRouter;
    IERC20 token;

    constructor() {
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 bnTokenAmountToSwap,
        uint256 bnAmountOutMin,
        address tokenAddress,
        address wethAddress,
        address publicKey,
        uint256 deadline
    ) public {
        token = IERC20(tokenAddress);
        token.transfer(address(this), bnTokenAmountToSwap);
        address[] memory t = new address[](2);

        t[0] = tokenAddress;
        t[1] = wethAddress;

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            bnTokenAmountToSwap,
            bnAmountOutMin,
            t,
            publicKey,
            deadline
        );
    }

    // important to receive ETH
    receive() external payable {}
}
