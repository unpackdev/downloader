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
///@notice This contract adds liquidity to 1inch mooniswap pools using any token
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "./ZapBaseV1.sol";

interface IMooniswap {
    function getTokens() external view returns (address[] memory tokens);

    function tokens(uint256 i) external view returns (IERC20);

    function deposit(
        uint256[2] calldata maxAmounts,
        uint256[2] calldata minAmounts
    )
        external
        payable
        returns (uint256 fairSupply, uint256[2] memory receivedAmounts);

    function depositFor(
        uint256[2] calldata maxAmounts,
        uint256[2] calldata minAmounts,
        address target
    )
        external
        payable
        returns (uint256 fairSupply, uint256[2] memory receivedAmounts);
}

contract Mooniswap_ZapIn_V1 is ZapBaseV1 {
    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice Adds liquidity to 1inch pools with an any token
    @param fromToken The ERC20 token used for investment (address(0x00) if ether)
    @param toPool The 1inch pool to add liquidity to
    @param minPoolTokens Minimum acceptable quantity of LP tokens to receive
    @param fromTokenAmounts Quantities of fromToken to invest into each poolToken
    @param swapTargets Excecution targets for both swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    @return Quantitiy of LP received
     */

    function ZapIn(
        address fromToken,
        address toPool,
        uint256 minPoolTokens,
        uint256[] calldata fromTokenAmounts,
        address[] calldata swapTargets,
        bytes[] calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 lpReceived) {
        // get incoming tokens
        uint256[2] memory toInvest =
            _pullTokens(fromToken, fromTokenAmounts, affiliate);

        uint256[] memory amounts = new uint256[](2);

        // get underlying tokens
        address[] memory tokens = IMooniswap(toPool).getTokens();

        // No swap if fromToken is underlying
        if (fromToken == tokens[0]) {
            amounts[0] = toInvest[0];
        } else {
            // swap 50% fromToken to token 0
            amounts[0] = _fillQuote(
                fromToken,
                tokens[0],
                toInvest[0],
                swapTargets[0],
                swapData[0]
            );
        }
        // No swap if fromToken is underlying
        if (fromToken == tokens[1]) {
            amounts[1] = toInvest[1];
        } else {
            // swap 50% fromToken to token 1
            amounts[1] = _fillQuote(
                fromToken,
                tokens[1],
                toInvest[1],
                swapTargets[1],
                swapData[1]
            );
        }

        lpReceived = _inchDeposit(tokens, amounts, toPool);

        require(lpReceived >= minPoolTokens, "ERR: High Slippage");
    }

    function _inchDeposit(
        address[] memory tokens,
        uint256[] memory amounts,
        address toPool
    ) internal returns (uint256 lpReceived) {
        // minToken amounts = 90% of token amounts
        uint256[2] memory minAmounts =
            [amounts[0].mul(90).div(100), amounts[1].mul(90).div(100)];
        uint256[2] memory receivedAmounts;

        // tokens[1] is never ETH, approving for both cases
        IERC20(tokens[1]).safeApprove(toPool, 0);
        IERC20(tokens[1]).safeApprove(toPool, amounts[1]);

        if (tokens[0] == address(0)) {
            (lpReceived, receivedAmounts) = IMooniswap(toPool).depositFor.value(
                amounts[0]
            )([amounts[0], amounts[1]], minAmounts, msg.sender);
        } else {
            IERC20(tokens[0]).safeApprove(toPool, 0);
            IERC20(tokens[0]).safeApprove(toPool, amounts[0]);
            (lpReceived, receivedAmounts) = IMooniswap(toPool).depositFor(
                [amounts[0], amounts[1]],
                minAmounts,
                msg.sender
            );
        }

        emit zapIn(msg.sender, toPool, lpReceived);

        // transfer any residue
        for (uint8 i = 0; i < 2; i++) {
            if (amounts[i] > receivedAmounts[i] + 1) {
                _transferTokens(tokens[i], amounts[i].sub(receivedAmounts[i]));
            }
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;
        if (fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            IERC20 fromToken = IERC20(fromTokenAddress);
            fromToken.safeApprove(address(swapTarget), 0);
            fromToken.safeApprove(address(swapTarget), amount);
        }

        uint256 iniBal = _getBalance(toToken);
        (bool success, ) = swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal.sub(iniBal);
    }

    function _transferTokens(address token, uint256 amt) internal {
        if (token == address(0)) {
            Address.sendValue(msg.sender, amt);
        } else {
            IERC20(token).safeTransfer(msg.sender, amt);
        }
    }

    function _pullTokens(
        address fromToken,
        uint256[] memory fromTokenAmounts,
        address affiliate
    ) internal returns (uint256[2] memory toInvest) {
        if (fromToken == address(0)) {
            require(msg.value > 0, "No eth sent");
            require(
                fromTokenAmounts[0].add(fromTokenAmounts[1]) == msg.value,
                "msg.value != fromTokenAmounts"
            );
        } else {
            require(msg.value == 0, "Eth sent with token");

            // transfer token
            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                fromTokenAmounts[0].add(fromTokenAmounts[1])
            );
        }

        toInvest[0] = fromTokenAmounts[0].sub(
            _subtractGoodwill(fromToken, fromTokenAmounts[0], affiliate)
        );
        toInvest[1] = fromTokenAmounts[1].sub(
            _subtractGoodwill(fromToken, fromTokenAmounts[1], affiliate)
        );
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (!whitelisted && goodwill > 0) {
            totalGoodwillPortion = SafeMath.div(
                SafeMath.mul(amount, goodwill),
                10000
            );

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    totalGoodwillPortion.mul(affiliateSplit).div(100);
                affiliateBalance[affiliate][token] = affiliateBalance[
                    affiliate
                ][token]
                    .add(affiliatePortion);
                totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
                    affiliatePortion
                );
            }
        }
    }
}
