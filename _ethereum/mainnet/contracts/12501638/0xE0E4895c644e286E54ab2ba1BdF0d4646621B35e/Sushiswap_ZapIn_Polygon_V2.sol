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
///@notice This contract adds liquidity to Sushiswap pools on Polygon using ETH or any ERC20 Token.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "./ZapInBaseV2.sol";

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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract Sushiswap_ZapIn_Polygon_V2 is ZapInBaseV2 {
    // sushiSwap
    IUniswapV2Router02 private constant sushiSwapRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IUniswapV2Factory private constant sushiSwapFactoryAddress =
        IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice This function is used to invest in given Sushiswap pair through ETH/ERC20 Tokens
    @param fromToken The ERC20 token used for investment (address(0x00) if ether)
    @param pairAddress The Sushiswap pair address
    @param amount The amount of fromToken to invest
    @param minPoolTokens Reverts if less tokens received than this
    @param swapTarget Excecution target for the first swap
    @param allowanceTarget Target to approve for swap
    @param swapData Dex quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @param shouldSellEntireBalance True if amountIn is determined at execution time (i.e. contract is caller)
    @return Amount of LP bought
     */
    function ZapIn(
        address fromToken,
        address pairAddress,
        uint256 amount,
        uint256 minPoolTokens,
        address swapTarget,
        address allowanceTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256) {
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amount,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        uint256 LPBought =
            _performZapIn(
                fromToken,
                pairAddress,
                toInvest,
                swapTarget,
                allowanceTarget,
                swapData,
                transferResidual
            );
        require(LPBought >= minPoolTokens, "ERR: High Slippage");

        emit zapIn(msg.sender, pairAddress, LPBought);

        IERC20(pairAddress).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

    function _getPairTokens(address pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair sushiPair = IUniswapV2Pair(pairAddress);
        token0 = sushiPair.token0();
        token1 = sushiPair.token1();
    }

    function _performZapIn(
        address fromToken,
        address pairAddress,
        uint256 amount,
        address swapTarget,
        address allowanceTarget,
        bytes memory swapData,
        bool transferResidual
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (address _ToSushipoolToken0, address _ToSushipoolToken1) =
            _getPairTokens(pairAddress);

        if (
            fromToken != _ToSushipoolToken0 && fromToken != _ToSushipoolToken1
        ) {
            // swap to intermediate
            (intermediateAmt, intermediateToken) = _fillQuote(
                fromToken,
                pairAddress,
                amount,
                swapTarget,
                allowanceTarget,
                swapData
            );
        } else {
            intermediateToken = fromToken;
            intermediateAmt = amount;
        }
        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) =
            _swapIntermediate(
                intermediateToken,
                _ToSushipoolToken0,
                _ToSushipoolToken1,
                intermediateAmt
            );

        return
            _sushiDeposit(
                _ToSushipoolToken0,
                _ToSushipoolToken1,
                token0Bought,
                token1Bought,
                transferResidual
            );
    }

    function _sushiDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        bool transferResidual
    ) internal returns (uint256) {
        _approveToken(_ToUnipoolToken0, address(sushiSwapRouter), token0Bought);
        _approveToken(_ToUnipoolToken1, address(sushiSwapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            sushiSwapRouter.addLiquidity(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        if (transferResidual) {
            //Returning Residue in token0, if any.
            if (token0Bought.sub(amountA) > 0) {
                IERC20(_ToUnipoolToken0).safeTransfer(
                    msg.sender,
                    token0Bought.sub(amountA)
                );
            }

            //Returning Residue in token1, if any
            if (token1Bought.sub(amountB) > 0) {
                IERC20(_ToUnipoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought.sub(amountB)
                );
            }
        }

        return LP;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address pairAddress,
        uint256 amount,
        address swapTarget,
        address allowanceTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amountBought, address intermediateToken) {
        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(_fromTokenAddress, allowanceTarget, amount);
        }

        (address _token0, address _token1) = _getPairTokens(pairAddress);
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));

        (bool success, ) = swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBalance0 =
            token0.balanceOf(address(this)).sub(initialBalance0);
        uint256 finalBalance1 =
            token1.balanceOf(address(this)).sub(initialBalance1);

        if (finalBalance0 > finalBalance1) {
            amountBought = finalBalance0;
            intermediateToken = _token0;
        } else {
            amountBought = finalBalance1;
            intermediateToken = _token1;
        }

        require(amountBought > 0, "Swapped to Invalid Intermediate");
    }

    function _swapIntermediate(
        address _toContractAddress,
        address _ToSushipoolToken0,
        address _ToSushipoolToken1,
        uint256 amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                sushiSwapFactoryAddress.getPair(
                    _ToSushipoolToken0,
                    _ToSushipoolToken1
                )
            );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_toContractAddress == _ToSushipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = amount.div(2);
            token1Bought = _token2Token(
                _toContractAddress,
                _ToSushipoolToken1,
                amountToSwap
            );
            token0Bought = amount.sub(amountToSwap);
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = amount.div(2);
            token0Bought = _token2Token(
                _toContractAddress,
                _ToSushipoolToken0,
                amountToSwap
            );
            token1Bought = amount.sub(amountToSwap);
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            Babylonian
                .sqrt(
                reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))
            )
                .sub(reserveIn.mul(1997)) / 1994;
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param fromToken The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address fromToken,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (fromToken == _ToTokenContractAddress) {
            return tokens2Trade;
        }
        _approveToken(fromToken, address(sushiSwapRouter), tokens2Trade);

        address pair =
            sushiSwapFactoryAddress.getPair(fromToken, _ToTokenContractAddress);
        require(pair != address(0), "No Swap Available");

        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = _ToTokenContractAddress;

        tokenBought = sushiSwapRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }
}
