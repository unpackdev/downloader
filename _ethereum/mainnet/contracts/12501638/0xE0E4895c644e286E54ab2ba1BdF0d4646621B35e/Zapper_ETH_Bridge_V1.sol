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
///@notice This contract swaps and bridges Matic Tokens to Ethereum mainnet
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;

import "./ZapInBaseV1.sol";

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

interface IChildToken {
    function withdraw(uint256 amount) external;
}

contract Zapper_ETH_Bridge_V1 is ZapInBaseV1 {
    IUniswapV2Factory private constant quickswapFactory =
        IUniswapV2Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    IUniswapV2Router02 private constant quickswapRouter =
        IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    IUniswapV2Factory private constant sushiswapFactory =
        IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);
    IUniswapV2Router02 private constant sushiswapRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    address private constant wmaticTokenAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    function ZapBridge(
        address fromToken,
        uint256 amountIn,
        address toToken,
        bool useSushi,
        address affiliate
    ) external payable stopInEmergency {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        uint256 toTokenAmt;
        if (useSushi) {
            toTokenAmt = _token2TokenSushi(fromToken, toToken, toInvest);
        } else {
            toTokenAmt = _token2TokenQuick(fromToken, toToken, toInvest);
        }

        IChildToken(toToken).withdraw(toTokenAmt);
    }

    /**
    @notice This function is used to swap MATIC/ERC20 <> MATIC/ERC20 via Quickswap
    @param fromTokenAddress The token address to swap from. (0x00 for ETH)
    @param _ToTokenContractAddress The token address to swap to. (0x00 for ETH)
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2TokenQuick(
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

    /**
    @notice This function is used to swap MATIC/ERC20 <> MATIC/ERC20 via Sushiswap
    @param fromTokenAddress The token address to swap from. (0x00 for ETH)
    @param _ToTokenContractAddress The token address to swap to. (0x00 for ETH)
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2TokenSushi(
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
            tokenBought = sushiswapRouter.swapExactETHForTokens.value(
                tokens2Trade
            )(1, path, address(this), deadline)[path.length - 1];
        } else if (_ToTokenContractAddress == address(0)) {
            if (fromTokenAddress == wmaticTokenAddress) {
                IWETH(wmaticTokenAddress).withdraw(tokens2Trade);
                return tokens2Trade;
            }

            IERC20(fromTokenAddress).safeApprove(
                address(sushiswapRouter),
                tokens2Trade
            );

            address[] memory path = new address[](2);
            path[0] = fromTokenAddress;
            path[1] = wmaticTokenAddress;
            tokenBought = sushiswapRouter.swapExactTokensForETH(
                tokens2Trade,
                1,
                path,
                address(this),
                deadline
            )[path.length - 1];
        } else {
            IERC20(fromTokenAddress).safeApprove(
                address(sushiswapRouter),
                tokens2Trade
            );

            if (fromTokenAddress != wmaticTokenAddress) {
                if (_ToTokenContractAddress != wmaticTokenAddress) {
                    // check output via tokenA -> tokenB
                    address pairA =
                        sushiswapFactory.getPair(
                            fromTokenAddress,
                            _ToTokenContractAddress
                        );
                    address[] memory pathA = new address[](2);
                    pathA[0] = fromTokenAddress;
                    pathA[1] = _ToTokenContractAddress;
                    uint256 amtA;
                    if (pairA != address(0)) {
                        amtA = sushiswapRouter.getAmountsOut(
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
                        sushiswapRouter.getAmountsOut(tokens2Trade, pathB)[2];

                    if (amtA >= amtB) {
                        tokenBought = sushiswapRouter.swapExactTokensForTokens(
                            tokens2Trade,
                            1,
                            pathA,
                            address(this),
                            deadline
                        )[pathA.length - 1];
                    } else {
                        tokenBought = sushiswapRouter.swapExactTokensForTokens(
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

                    tokenBought = sushiswapRouter.swapExactTokensForTokens(
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
                tokenBought = sushiswapRouter.swapExactTokensForTokens(
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
