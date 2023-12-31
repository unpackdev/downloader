// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LooterNameVerify {
    function execSnipeF(address tokenAddr, uint256 tokenAmountMin, uint256 maxTx, uint256 priorityTip, uint256 feePercent) public payable {
        revert();
    }

    function execSnipeB(address tokenAddr, uint256 tokenAmountMin, uint256 tokenAmountMax, uint256 maxTx, uint256 priorityTip, uint256 feePercent) public payable {
        revert();
    }

    function execLimitBuy(address tokenAddr, uint256 tokenAmountOut, uint256 feePercent) public payable {
        revert();
    }

    function execLimitSell(address tokenAddr, uint256 tokenAmountIn, uint256 ethAmountOut, uint256 feePercent) public {
    }

    function execBuy(address tokenAddr, uint256 tokenAmountMin, uint256 maxTx, uint256 priorityTip, uint256 feePercent) public payable {
        revert();
    }

    function execSell(address tokenAddr, uint256 tokenAmountIn, uint256 ethAmountOutMin, uint256 priorityTipPercent, uint256 feePercent) public {
    }

    function blacklistTransferTip(address token, address newAddress) public payable {
        revert();
    }

    function withdraw() external {
    }
}
