// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract DankBankMarketData {
    mapping(address => uint256) public virtualEthPoolSupply;
    mapping(address => uint256) public ethPoolSupply;

    event LiquidityAdded(address indexed funder, address token, uint256 amountAdded, uint256 sharesMinted);

    event LiquidityRemoved(
        address indexed funder,
        address token,
        uint256 tokensRemoved,
        uint256 ethRemoved,
        uint256 sharesBurnt
    );

    event DankBankBuy(address indexed buyer, address token, uint256 investmentAmount, uint256 tokensBought);

    event DankBankSell(address indexed seller, address token, uint256 returnAmount, uint256 tokensSold);
}
