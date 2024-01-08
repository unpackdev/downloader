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
///@notice This contract adds liquidity to Mushroom Vaults using ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapInBaseV3.sol";

interface IWETH {
    function deposit() external payable;
}

interface IMVault {
    function deposit(uint256) external;

    function token() external view returns (address);
}

contract Mushroom_ZapIn_V2 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        address _curveZapIn,
        address _uniZapIn,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2(_goodwill, _affiliateSplit) {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        // Curve ZapIn
        approvedTargets[_curveZapIn] = true;
        // Uniswap ZapIn
        approvedTargets[_uniZapIn] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
        @notice This function adds liquidity to Mushroom vaults with ETH or ERC20 tokens
        @param fromToken The token used for entry (address(0) if ether)
        @param amountIn The amount of fromToken to invest
        @param toVault Harvest vault address
        @param minMVTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
        @param intermediateToken Token to swap fromToken to before entering vault
        @param swapTarget Excecution target for the swap or zap
        @param swapData DEX or Zap data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance True if amountIn is determined at execution time (i.e. contract is caller)
        @return tokensReceived Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toVault,
        uint256 minMVTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        // get incoming tokens
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amountIn,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        // get intermediate token
        uint256 intermediateAmt =
            _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );

        // Deposit to Vault
        tokensReceived = _vaultDeposit(intermediateAmt, toVault, minMVTokens);
    }

    function _vaultDeposit(
        uint256 amount,
        address toVault,
        uint256 minTokensRec
    ) internal returns (uint256 tokensReceived) {
        address underlyingVaultToken = IMVault(toVault).token();

        _approveToken(underlyingVaultToken, toVault);

        uint256 iniVaultBal = IERC20(toVault).balanceOf(address(this));
        IMVault(toVault).deposit(amount);
        tokensReceived = IERC20(toVault).balanceOf(address(this)) - iniVaultBal;
        require(tokensReceived >= minTokensRec, "High Slippage");

        IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
        emit zapIn(msg.sender, toVault, tokensReceived);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amtBought) {
        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal - iniBal;
    }
}
