// SPDX-License-Identifier: Unlicensed

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}


pragma solidity ^0.8.0;
import "./ISaltsToken.sol";

contract SingleSwap {

    IUniswapV2Router02 public swapRouter;
    ISaltsToken public saltsToken;

    constructor(address _saltsToken, address _routerAddress) {
        saltsToken = ISaltsToken(_saltsToken);
        swapRouter = IUniswapV2Router02(_routerAddress);
    }

    function swapExactEthForTokens(uint256 amountOutMin,address[] calldata path,address recipient,address _referer)
    external payable
    {
        saltsToken.registerUser(recipient, _referer);
        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(amountOutMin,path,recipient,block.timestamp+1000);
    }
}