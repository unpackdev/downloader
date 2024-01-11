//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IERC20Pro {

    function initialize(string[] calldata tickers, uint maxTxAmount, uint maxWalletAmount, uint[] calldata fees, address[] calldata addresses) external;

    function createLiquidity(uint tokensToLiquidity) external;

    function openTrading() external;

}
