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
///@notice This contract allows minting and staking of cvxCRV and cvxCurveLP tokens
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapInBaseV3_1.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface IConvexCrvDepositor {
    function deposit(uint256 _amount, bool _lock) external;
}

interface IConvexBooster {
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );
}

interface IConvexRewards {
    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function balanceOf(address _user) external view returns (uint256);
}

contract Convex_ZapIn_V1 is ZapInBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant crvTokenAddress =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant cvxCrvTokenAddress =
        0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;

    IConvexCrvDepositor depositor =
        IConvexCrvDepositor(0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae);
    IConvexBooster booster =
        IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    constructor(
        address _curveZapIn,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2_1(_goodwill, _affiliateSplit) {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        approvedTargets[_curveZapIn] = true;
    }

    event zapIn(
        address sender,
        address token,
        uint256 tokensRec,
        address affiliate
    );

    /**
    @notice This function adds and stakes liquidity into Convex pools with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromTokenAddress to invest
    @param pid The ID of the Convex pool to enter
    @param minLPTokens The minimum acceptable quantity of Curve LP to receive. Reverts otherwise
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @return crvLPReceived Quantity of Curve LP tokens received
    */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        uint256 pid,
        uint256 minLPTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 crvLPReceived) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        (address crvLpToken, address cvxToken, , address rewardContract, , ) =
            booster.poolInfo(pid);

        crvLPReceived = _fillQuote(
            fromToken,
            crvLpToken,
            toInvest,
            swapTarget,
            swapData
        );
        require(crvLPReceived >= minLPTokens, "High Slippage");

        _approveToken(crvLpToken, address(booster), crvLPReceived);
        booster.deposit(pid, crvLPReceived, false);

        _approveToken(cvxToken, rewardContract, crvLPReceived);
        IConvexRewards(rewardContract).stakeFor(msg.sender, crvLPReceived);

        emit zapIn(msg.sender, crvLpToken, crvLPReceived, affiliate);
    }

    /**
    @notice This function mints and deposits cvxCRV tokens with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromTokenAddress to invest
    @param minCRVTokens The minimum acceptable quantity of Curve tokens receive. Reverts otherwise
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @return cvxCrvReceived Quantity of cvxCRV tokens received
    */
    function ZapInCvxCRV(
        address fromToken,
        uint256 amountIn,
        uint256 minCRVTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 cvxCrvReceived) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        uint256 crvBought =
            _fillQuote(
                fromToken,
                crvTokenAddress,
                toInvest,
                swapTarget,
                swapData
            );
        require(crvBought >= minCRVTokens, "High Slippage");

        _approveToken(crvTokenAddress, address(depositor), crvBought);
        depositor.deposit(crvBought, false);

        IERC20(cvxCrvTokenAddress).safeTransfer(msg.sender, crvBought);

        emit zapIn(msg.sender, crvTokenAddress, crvBought, affiliate);

        return crvBought;
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

        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(_amount);
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
