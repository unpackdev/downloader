/**
 * Modified version of the UniswapV2Library to use inbuilt SafeMath
 * Also supports Toad struct stuff
 */
//SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.20;

import "./IUniswapV2Pair.sol";

import "./ToadStructs.sol";

library ToadswapLibrary {


    error InsufficientAmount();
    error InsufficientLiquidity();
    error IdenticalAddress();
    error ZeroAddress();
    error InvalidPathLib();

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'ToadswapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ToadswapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a UniswapV2 pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        pair = pairFor(tokenA, tokenB, ToadStructs.DexData(hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f', factory));
    }


    function pairFor(address tokenA, address tokenB, ToadStructs.DexData memory dex) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            dex.factory,
            keccak256(abi.encodePacked(token0, token1)),
            dex.initcode // init code hash

        )))));

    }

    function getDexId(ToadStructs.AggPath memory path, ToadStructs.DexData[] memory dexes ) internal pure returns(ToadStructs.DexData memory dex) {
        dex = dexes[path.dexId];
    }


    function getPriceOut(uint256 amountIn, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) internal view returns (uint256[] memory amounts) {
        if(path.length < 2) {
            revert InvalidPathLib();
        }
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {

            (uint reserveIn, uint reserveOut) = getReserves(path[i].token, path[i + 1].token, dexes[path[i+1].dexId]);
            amounts[i + 1] = quote(amounts[i], reserveIn, reserveOut);
        }
    }


    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, ToadStructs.DexData memory dex) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(tokenA, tokenB, dex)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        if (amountA == 0) {
            revert InsufficientAmount();
        }
        if(reserveA == 0 && reserveB == 0) {
            revert InsufficientLiquidity();
        }
    
        amountB = amountA * (reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        if (amountIn == 0) {
            revert InsufficientAmount();
        }
        if(reserveIn == 0 && reserveOut == 0) {
            revert InsufficientLiquidity();
        }
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        if (amountOut == 0) {
            revert InsufficientAmount();
        }
        if(reserveIn == 0 && reserveOut == 0) {
            revert InsufficientLiquidity();
        }
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, ToadStructs.AggPath[] memory path, ToadStructs.DexData[] memory dexes, address vETH, address WETH) internal view returns (uint[] memory amounts) {
        if(path.length < 2) {
            revert InvalidPathLib();
        }
        if(path[0].token == vETH) {
            path[0].token = WETH;
        }
        amounts = new uint[](path.length);
        amounts[0] = amountIn;

        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i].token, path[i + 1].token, dexes[path[i+1].dexId]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }


    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(uint amountOut, ToadStructs.AggPath[] memory path, ToadStructs.DexData[] memory dexes, address vETH, address WETH) internal view returns (uint[] memory amounts) {
        if(path.length < 2) {
            revert InvalidPathLib();
        }
        if(path[0].token == vETH) {
            path[0].token = WETH;
        }
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i - 1].token, path[i].token, dexes[path[i].dexId]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }


}
