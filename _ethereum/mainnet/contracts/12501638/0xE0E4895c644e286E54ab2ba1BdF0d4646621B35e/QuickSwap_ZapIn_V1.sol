// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 Zapper

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
///@notice This contract adds liquidity to QuickSwap pools using any arbitrary token
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "./ZapInBaseV1.sol";

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

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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

contract QuickSwap_ZapIn_V1 is ZapInBaseV1 {
    IUniswapV2Router02 private constant quickswapRouter =
        IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    IUniswapV2Factory private constant quickswapFactory =
        IUniswapV2Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);

    address private constant wmaticTokenAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice Adds liquidity to QuickSwap Pools with any token
    @param fromTokenAddress ERC20 token address used for investment (address(0x00) if MATIC)
    @param pairAddress QuickSwap pair address
    @param amount Quantity of fromTokenAddress to invest
    @param minPoolTokens Minimum acceptable quantity of LP tokens to receive.
    @param affiliate Affiliate address
    @return Quantity of LP bought
     */
    function ZapIn(
        address fromTokenAddress,
        address pairAddress,
        uint256 amount,
        uint256 minPoolTokens,
        address affiliate
    ) public payable stopInEmergency returns (uint256) {
        uint256 toInvest =
            _pullTokens(fromTokenAddress, amount, affiliate, true);

        uint256 LPBought =
            _performZapIn(fromTokenAddress, pairAddress, toInvest);

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
        IUniswapV2Pair uniPair = IUniswapV2Pair(pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _performZapIn(
        address fromTokenAddress,
        address pairAddress,
        uint256 amount
    ) internal returns (uint256) {
        (address _token0, address _token1) = _getPairTokens(pairAddress);
        address intermediate =
            _getIntermediate(fromTokenAddress, amount, _token0, _token1);

        // swap to intermediate
        uint256 interAmt = _token2Token(fromTokenAddress, intermediate, amount);

        // divide to swap in amounts
        uint256 token0Bought;
        uint256 token1Bought;

        IUniswapV2Pair pair =
            IUniswapV2Pair(quickswapFactory.getPair(_token0, _token1));
        (uint256 res0, uint256 res1, ) = pair.getReserves();

        if (intermediate == _token0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, interAmt);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = interAmt.div(2);
            token1Bought = _token2Token(intermediate, _token1, amountToSwap);
            token0Bought = interAmt.sub(amountToSwap);
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, interAmt);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = interAmt.div(2);
            token0Bought = _token2Token(intermediate, _token0, amountToSwap);
            token1Bought = interAmt.sub(amountToSwap);
        }

        return _quickDeposit(_token0, _token1, token0Bought, token1Bought);
    }

    function _quickDeposit(
        address _token0,
        address _token1,
        uint256 token0Bought,
        uint256 token1Bought
    ) internal returns (uint256) {
        IERC20(_token0).safeApprove(address(quickswapRouter), token0Bought);
        IERC20(_token1).safeApprove(address(quickswapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            quickswapRouter.addLiquidity(
                _token0,
                _token1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        IERC20(_token0).safeApprove(address(quickswapRouter), 0);
        IERC20(_token1).safeApprove(address(quickswapRouter), 0);

        //Returning Residue in token0, if any.
        if (token0Bought.sub(amountA) > 0) {
            IERC20(_token0).safeTransfer(msg.sender, token0Bought.sub(amountA));
        }

        //Returning Residue in token1, if any
        if (token1Bought.sub(amountB) > 0) {
            IERC20(_token1).safeTransfer(msg.sender, token1Bought.sub(amountB));
        }

        return LP;
    }

    function _getIntermediate(
        address fromTokenAddress,
        uint256 amount,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1
    ) internal view returns (address) {
        // set from to wmatic for matic input
        if (fromTokenAddress == address(0)) {
            fromTokenAddress = wmaticTokenAddress;
        }

        if (fromTokenAddress == _ToUnipoolToken0) {
            return _ToUnipoolToken0;
        } else if (fromTokenAddress == _ToUnipoolToken1) {
            return _ToUnipoolToken1;
        } else if (
            _ToUnipoolToken0 == wmaticTokenAddress ||
            _ToUnipoolToken1 == wmaticTokenAddress
        ) {
            return wmaticTokenAddress;
        } else {
            IUniswapV2Pair pair =
                IUniswapV2Pair(
                    quickswapFactory.getPair(_ToUnipoolToken0, _ToUnipoolToken1)
                );
            (uint256 res0, uint256 res1, ) = pair.getReserves();

            uint256 ratio;
            bool isToken0Numerator;
            if (res0 >= res1) {
                ratio = res0 / res1;
                isToken0Numerator = true;
            } else {
                ratio = res1 / res0;
            }

            //find outputs on swap
            uint256 output0 =
                _calculateSwapOutput(
                    fromTokenAddress,
                    amount,
                    _ToUnipoolToken0
                );
            uint256 output1 =
                _calculateSwapOutput(
                    fromTokenAddress,
                    amount,
                    _ToUnipoolToken1
                );

            if (isToken0Numerator) {
                if (output1 * ratio >= output0) return _ToUnipoolToken1;
                else return _ToUnipoolToken0;
            } else {
                if (output0 * ratio >= output1) return _ToUnipoolToken0;
                else return _ToUnipoolToken1;
            }
        }
    }

    function _calculateSwapOutput(
        address _from,
        uint256 _amt,
        address _to
    ) internal view returns (uint256) {
        // check output via tokenA -> tokenB
        address pairA = quickswapFactory.getPair(_from, _to);

        uint256 amtA;
        if (pairA != address(0)) {
            address[] memory pathA = new address[](2);
            pathA[0] = _from;
            pathA[1] = _to;

            amtA = quickswapRouter.getAmountsOut(_amt, pathA)[1];
        }

        uint256 amtB;
        // check output via tokenA -> wmatic -> tokenB
        if ((_from != wmaticTokenAddress) && _to != wmaticTokenAddress) {
            address[] memory pathB = new address[](3);
            pathB[0] = _from;
            pathB[1] = wmaticTokenAddress;
            pathB[2] = _to;

            amtB = quickswapRouter.getAmountsOut(_amt, pathB)[2];
        }

        if (amtA >= amtB) {
            return amtA;
        } else {
            return amtB;
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
    @notice This function is used to swap ETH/ERC20 <> ETH/ERC20
    @param fromTokenAddress The token address to swap from. (0x00 for ETH)
    @param _ToTokenContractAddress The token address to swap to. (0x00 for ETH)
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address fromTokenAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (fromTokenAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        if (fromTokenAddress == address(0)) {
            if (_ToTokenContractAddress == wmaticTokenAddress) {
                IWETH(wmaticTokenAddress).deposit.value(tokens2Trade)();
                return tokens2Trade;
            }

            address[] memory path = new address[](2);
            path[0] = wmaticTokenAddress;
            path[1] = _ToTokenContractAddress;
            tokenBought = quickswapRouter.swapExactETHForTokens.value(
                tokens2Trade
            )(1, path, address(this), deadline)[path.length - 1];
        } else if (_ToTokenContractAddress == address(0)) {
            if (fromTokenAddress == wmaticTokenAddress) {
                IWETH(wmaticTokenAddress).withdraw(tokens2Trade);
                return tokens2Trade;
            }

            IERC20(fromTokenAddress).safeApprove(
                address(quickswapRouter),
                tokens2Trade
            );

            address[] memory path = new address[](2);
            path[0] = fromTokenAddress;
            path[1] = wmaticTokenAddress;
            tokenBought = quickswapRouter.swapExactTokensForETH(
                tokens2Trade,
                1,
                path,
                address(this),
                deadline
            )[path.length - 1];
        } else {
            IERC20(fromTokenAddress).safeApprove(
                address(quickswapRouter),
                tokens2Trade
            );

            if (fromTokenAddress != wmaticTokenAddress) {
                if (_ToTokenContractAddress != wmaticTokenAddress) {
                    // check output via tokenA -> tokenB
                    address pairA =
                        quickswapFactory.getPair(
                            fromTokenAddress,
                            _ToTokenContractAddress
                        );
                    address[] memory pathA = new address[](2);
                    pathA[0] = fromTokenAddress;
                    pathA[1] = _ToTokenContractAddress;
                    uint256 amtA;
                    if (pairA != address(0)) {
                        amtA = quickswapRouter.getAmountsOut(
                            tokens2Trade,
                            pathA
                        )[1];
                    }

                    // check output via tokenA -> wmatic -> tokenB
                    address[] memory pathB = new address[](3);
                    pathB[0] = fromTokenAddress;
                    pathB[1] = wmaticTokenAddress;
                    pathB[2] = _ToTokenContractAddress;

                    uint256 amtB =
                        quickswapRouter.getAmountsOut(tokens2Trade, pathB)[2];

                    if (amtA >= amtB) {
                        tokenBought = quickswapRouter.swapExactTokensForTokens(
                            tokens2Trade,
                            1,
                            pathA,
                            address(this),
                            deadline
                        )[pathA.length - 1];
                    } else {
                        tokenBought = quickswapRouter.swapExactTokensForTokens(
                            tokens2Trade,
                            1,
                            pathB,
                            address(this),
                            deadline
                        )[pathB.length - 1];
                    }
                } else {
                    address[] memory path = new address[](2);
                    path[0] = fromTokenAddress;
                    path[1] = wmaticTokenAddress;

                    tokenBought = quickswapRouter.swapExactTokensForTokens(
                        tokens2Trade,
                        1,
                        path,
                        address(this),
                        deadline
                    )[path.length - 1];
                }
            } else {
                address[] memory path = new address[](2);
                path[0] = wmaticTokenAddress;
                path[1] = _ToTokenContractAddress;
                tokenBought = quickswapRouter.swapExactTokensForTokens(
                    tokens2Trade,
                    1,
                    path,
                    address(this),
                    deadline
                )[path.length - 1];
            }
        }
        require(tokenBought > 0, "Error Swapping Tokens");
    }
}
