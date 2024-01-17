/*
 * Buy Queuecoin - Queue
 *
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.17;

interface IDEXRouter {  
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}

contract BuyQueue{
    IDEXRouter public constant ROUTER = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant IMP = 0x2D5C73f3597B07F23C2bB3F2422932E67eca4543;
    address public constant QUEUE = 0xFb50D7d98A2e8CF2f63CC17d18e6712Ade3452B3;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() {}

    receive() external payable {}

    function buyQueueWithETH() external payable {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = IMP;
        path[2] = QUEUE;

        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }
}