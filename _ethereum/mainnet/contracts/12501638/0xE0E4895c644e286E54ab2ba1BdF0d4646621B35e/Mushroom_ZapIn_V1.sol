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
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "./ZapInBaseV2.sol";

interface IMVault {
    function deposit(uint256) external;

    function token() external view returns (address);
}

contract Mushroom_ZapIn_V1 is ZapInBaseV2 {
    mapping(address => bool) public approvedTargets;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

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
    @return tokensReceived- Quantity of Vault tokens received
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
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

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
        tokensReceived = IERC20(toVault).balanceOf(address(this)).sub(
            iniVaultBal
        );
        require(tokensReceived >= minTokensRec, "Err: High Slippage");

        IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
        emit zapIn(msg.sender, toVault, tokensReceived);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal.sub(iniBal);
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}
