// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolEvents {
    event PoolOpened(address operator, uint256 startTime, uint256 tokenDeposit);
    event PoolActiviated(uint256 funded);
    event PoolLiquidated(uint256 liquidityFund);
    event PoolDishonored(uint256 requiredFund, uint256 liquidityFund);
    event PoolReverted(uint256 minCapacity, uint256 funded);

    event OraclePriceChanged(uint256 oraclePrice);
    event PoolDetailLinkChanged(string link);
    event ColletralHashChanged(string oldHash, string newHash);
    event ColletralLinkChanged(string oldLink, string newLink);

    event Deposit(address token, address from, uint256 amount);
    event Withdrawal(address token, address from, address to, uint256 amount);
    event Claim(address from, address to, uint256 amount);
    event Exited(address from, address to, uint256 amount);
}