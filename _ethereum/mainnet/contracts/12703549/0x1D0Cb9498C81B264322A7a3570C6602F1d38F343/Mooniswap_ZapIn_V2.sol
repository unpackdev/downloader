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

///@author Zapper
///@notice This contract adds liquidity to 1inch mooniswap pools using any token
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "./ZapInBaseV3_1.sol";

// import "./Babylonian.sol";
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

interface IWETH {
    function deposit() external payable;
}

interface IMooniswap {
    function getTokens() external view returns (address[] memory);

    function tokens(uint256 i) external view returns (IERC20);

    function fee() external view returns (uint256);

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

    function swap(
        IERC20 src,
        IERC20 dst,
        uint256 amount,
        uint256 minReturn,
        address referral
    ) external payable returns (uint256 result);
}

contract Mooniswap_ZapIn_V2 is ZapInBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice Add liquidity to Mooniswap pools with ETH/ERC20 Tokens
    @param fromToken The ERC20 token used (address(0x00) if ether)
    @param amountIn The amount of fromToken to invest
    @param minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @return lpReceived Quantity of LP received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toPool,
        uint256 minPoolTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual
    ) external payable stopInEmergency returns (uint256 lpReceived) {
        uint256 intermediateAmt;

        {
            // get incoming tokens
            uint256 toInvest =
                _pullTokens(fromToken, amountIn, affiliate, true);

            // get intermediate pool token
            intermediateAmt = _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );
        }

        // fetch pool tokens
        address[] memory tokens = IMooniswap(toPool).getTokens();

        // divide intermediate into appropriate underlying tokens to add liquidity
        uint256[2] memory tokensBought =
            _swapIntermediate(
                toPool,
                tokens,
                intermediateToken,
                intermediateAmt
            );

        // add liquidity
        lpReceived = _inchDeposit(
            tokens,
            tokensBought,
            toPool,
            transferResidual
        );

        require(lpReceived >= minPoolTokens, "High Slippage");
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

    function _getReserves(address token, address user)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = user.balance;
        } else {
            balance = IERC20(token).balanceOf(user);
        }
    }

    function _swapIntermediate(
        address toPool,
        address[] memory tokens,
        address intermediateToken,
        uint256 intermediateAmt
    ) internal returns (uint256[2] memory tokensBought) {
        uint256[2] memory reserves =
            [_getReserves(tokens[0], toPool), _getReserves(tokens[1], toPool)];

        if (intermediateToken == tokens[0]) {
            uint256 amountToSwap =
                calculateSwapInAmount(reserves[0], intermediateAmt);

            tokensBought[1] = _token2Token(
                intermediateToken,
                tokens[1],
                amountToSwap,
                toPool
            );
            tokensBought[0] = intermediateAmt - amountToSwap;
        } else {
            uint256 amountToSwap =
                calculateSwapInAmount(reserves[1], intermediateAmt);

            tokensBought[0] = _token2Token(
                intermediateToken,
                tokens[0],
                amountToSwap,
                toPool
            );
            tokensBought[1] = intermediateAmt - amountToSwap;
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }

    function _token2Token(
        address fromToken,
        address toToken,
        uint256 amount,
        address viaPool
    ) internal returns (uint256 tokenBought) {
        uint256 valueToSend;
        if (fromToken != address(0)) {
            _approveToken(fromToken, viaPool);
        } else {
            valueToSend = amount;
        }

        tokenBought = IMooniswap(viaPool).swap{ value: valueToSend }(
            IERC20(fromToken),
            IERC20(toToken),
            amount,
            0,
            address(0)
        );
        require(tokenBought > 0, "Error Swapping Tokens 2");
    }

    function _inchDeposit(
        address[] memory tokens,
        uint256[2] memory amounts,
        address toPool,
        bool transferResidual
    ) internal returns (uint256 lpReceived) {
        uint256[2] memory minAmounts;
        uint256[2] memory receivedAmounts;
        // tokens[1] is never ETH, approving for both cases
        _approveToken(tokens[1], toPool);
        if (tokens[0] == address(0)) {
            (lpReceived, receivedAmounts) = IMooniswap(toPool).depositFor{
                value: amounts[0]
            }([amounts[0], amounts[1]], minAmounts, msg.sender);
        } else {
            _approveToken(tokens[0], toPool);
            (lpReceived, receivedAmounts) = IMooniswap(toPool).depositFor(
                [amounts[0], amounts[1]],
                minAmounts,
                msg.sender
            );
        }
        emit zapIn(msg.sender, toPool, lpReceived);
        if (transferResidual) {
            // transfer any residue
            if (amounts[0] > receivedAmounts[0]) {
                _transferTokens(tokens[0], amounts[0] - receivedAmounts[0]);
            }
            if (amounts[1] > receivedAmounts[1]) {
                _transferTokens(tokens[1], amounts[1] - receivedAmounts[1]);
            }
        }
    }

    function _transferTokens(address token, uint256 amt) internal {
        if (token == address(0)) {
            Address.sendValue(payable(msg.sender), amt);
        } else {
            IERC20(token).safeTransfer(msg.sender, amt);
        }
    }
}
