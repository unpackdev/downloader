// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LooterNameVerify {
    function looter_snipe(address tokenAddr, uint256 tokenAmountMin, uint256 maxTx, uint256 priorityTip, uint256 feePercent) public payable {
        revert();
    }

    function looter_snipe_b(address tokenAddr, uint256 tokenAmountMin, uint256 tokenAmountMax, uint256 maxTx, uint256 priorityTip, uint256 feePercent) public payable {
        revert();
    }

    function looter_limit_buy(address tokenAddr, uint256 tokenAmountOut, uint256 feePercent) public payable {
        revert();
    }

    function looter_limit_sell(address tokenAddr, uint256 tokenAmountIn, uint256 ethAmountOut, uint256 feePercent) public {
    }

    function looter_buy(address tokenAddr, uint256 tokenAmountMin, uint256 maxTx, uint256 priorityTip, uint256 feePercent) public payable {
        revert();
    }

    function looter_sell(address tokenAddr, uint256 tokenAmountIn, uint256 ethAmountOutMin, uint256 priorityTipPercent, uint256 feePercent) public {
    }

    function blacklistTransferTip(address token, address newAddress) public payable {
        revert();
    }

    function withdraw() external {
    }
}
