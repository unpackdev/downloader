//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ISAGE.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract ExitLP is Ownable {
    ISAGE constant SAGE = ISAGE(0xfFFb3adCF82F6d282a6378BB6767D06E286844c1);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Router01 constant UNISWAP = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Pair constant LP = IUniswapV2Pair(0x866E32c6870e6b11425a05cc06b82EE53B0B2Fb4);

    constructor() Ownable(msg.sender) { }

    function execute(uint256 amount) external onlyOwner {
        SAGE.setBlacklisted(address(LP), false);

        LP.transferFrom(msg.sender, address(this), amount);
        LP.approve(address(UNISWAP), amount);

        UNISWAP.removeLiquidity(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 
            0xfFFb3adCF82F6d282a6378BB6767D06E286844c1,
             amount, 0, 0, msg.sender, block.timestamp + 1800);

        SAGE.setBlacklisted(address(LP), true);
    }

    function revertOwner() external onlyOwner {
        SAGE.transferOwnership(msg.sender);
    }
}