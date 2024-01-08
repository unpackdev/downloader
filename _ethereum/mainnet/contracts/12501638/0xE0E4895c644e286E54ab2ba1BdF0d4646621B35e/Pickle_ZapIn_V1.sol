// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

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
///@notice This contract deposits to Pickle Jars with ETH or ERC tokens
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "./ZapInBaseV1.sol";

interface IPickleJar {
    function token() external view returns (address);

    function deposit(uint256 amount) external;
}

contract Pickle_ZapIn_V1 is ZapInBaseV1 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice This function adds liquidity to a Pickle vaults with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param toPJar Pickle vault address
    @param minPJarTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @param intermediateToken Token to swap fromToken to before entering vault
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensReceived- Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toPJar,
        uint256 minPJarTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        // get incoming tokens
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

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
        tokensReceived = _vaultDeposit(intermediateAmt, toPJar, minPJarTokens);
    }

    function _vaultDeposit(
        uint256 amount,
        address toVault,
        uint256 minTokensRec
    ) internal returns (uint256 tokensReceived) {
        address underlyingVaultToken = IPickleJar(toVault).token();

        _approveToken(underlyingVaultToken, toVault);

        uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));
        IPickleJar(toVault).deposit(amount);
        tokensReceived = IERC20(toVault).balanceOf(address(this)).sub(
            iniYVaultBal
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
