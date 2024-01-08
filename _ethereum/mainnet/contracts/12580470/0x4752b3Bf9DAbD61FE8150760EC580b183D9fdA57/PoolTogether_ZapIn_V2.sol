// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract enters Pool Together Prize Pools with ETH or ERC tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapInBaseV3.sol";

interface IWETH {
    function deposit() external payable;
}

interface IPoolTogether {
    function depositTo(
        address to,
        uint256 amount,
        address controlledToken,
        address referrer
    ) external;

    function tokens() external returns (address[] memory);

    function token() external returns (address);
}

contract PoolTogether_ZapIn_V2 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant zGoodwillAddress =
        0x3CE37278de6388532C3949ce4e886F365B14fB56;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
        @notice This function adds liquidity to a PoolTogether prize pool with ETH or ERC20 tokens
        @param fromToken The token used for entry (address(0) if ether)
        @param toToken The intermediate ERC20 token to swap to
        @param prizePool Prize pool to enter
        @param amountIn The quantity of fromToken to invest
        @param minTickets The minimum acceptable quantity of tickets to acquire. Reverts otherwise
        @param swapTarget Excecution target for swap
        @param swapData DEX quote data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
     */
    function ZapIn(
        address fromToken,
        address toToken,
        address prizePool,
        uint256 amountIn,
        uint256 minTickets,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency {
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amountIn,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        IPoolTogether _prizePool = IPoolTogether(prizePool);

        if (_prizePool.token() == fromToken) {
            _enterPrizePool(_prizePool, toInvest, minTickets);
        } else {
            uint256 tokensBought =
                _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);
            _enterPrizePool(_prizePool, tokensBought, minTickets);
        }
    }

    function _enterPrizePool(
        IPoolTogether prizePool,
        uint256 amount,
        uint256 minTickets
    ) internal {
        address poolToken = prizePool.token();
        address ticket = prizePool.tokens()[1];

        _approveToken(poolToken, address(prizePool));

        uint256 iniTicketBal = _getBalance(ticket);

        prizePool.depositTo(address(this), amount, ticket, zGoodwillAddress);

        uint256 ticketsRec = _getBalance(ticket) - iniTicketBal;

        require(ticketsRec >= minTickets, "High Slippage");

        IERC20(ticket).safeTransfer(msg.sender, ticketsRec);

        emit zapIn(msg.sender, address(prizePool), amount);
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 _amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return _amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 initialBalance = _getBalance(toToken);
        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");
        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }
}
