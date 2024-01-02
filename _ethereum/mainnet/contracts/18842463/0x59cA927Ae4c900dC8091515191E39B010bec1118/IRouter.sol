// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IRouter{
    function creatorAddLiquidityTokens(
        address tokenB,
        uint amountB,
        uint deadline
    ) external;

    function creatorAddLiquidityETH(
        address pool,
        uint deadline
    ) external payable;

    function userAddLiquidityETH(
        address pool,
        uint deadline
    ) external payable;

    function userRedeemLiquidity(
        address pool,
        uint deadline
    ) external;

    function swapETHForXSD(uint amountOut,uint deadline) external payable;

    function swapXSDForETH(uint amountOut, uint amountInMax, uint deadline) external;

    function swapETHForBankX(uint amountOut, uint deadline) external payable;
    
    function swapBankXForETH(uint amountOut, uint amountInMax, uint deadline) external;

    function swapBankXForXSD(uint bankx_amount, address sender, uint256 eth_min_amount, uint256 bankx_min_amount, uint256 deadline) external;

    function swapXSDForBankX(uint XSD_amount, address sender, uint256 eth_min_amount, uint256 xsd_min_amount, uint256 deadline) external;
}