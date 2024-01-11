// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IPYESwapPair.sol";
import "./IPYESwapFactory.sol";
import "./IToken.sol";
import "./IERC20.sol";

import "./SafeMath.sol";

library PYESwapLibrary {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PYESwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PYESwapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'7322d196a5476ed6b44fc18910ef3e8a09c2baea2da66bd2cf58f5b3c9dc57ce' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,,) = IPYESwapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PYESwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PYESwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, bool tokenFee, uint totalFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PYESwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PYESwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInMultiplier = tokenFee ? 10000 - totalFee : 10000;
        uint amountInWithFee = amountIn * amountInMultiplier;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 10000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, bool tokenFee, uint totalFee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PYESwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PYESwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountOutMultiplier = tokenFee ? 10000 - totalFee : 10000;
        uint numerator = (reserveIn * amountOut) * 10000;
        uint denominator = (reserveOut - amountOut) * amountOutMultiplier;
        amountIn = (numerator / denominator) + 1;
    }

    function amountsOut(address factory, uint amountIn, address[] memory path, bool isExcluded) internal view returns (uint[] memory) {
        return isExcluded ? getAmountsOutWithoutFee(factory, amountIn, path) : getAmountsOut(factory, amountIn, path);
    }

    function amountsIn(address factory, uint amountOut, address[] memory path, bool isExcluded) internal view returns (uint[] memory) {
        return isExcluded ? getAmountsInWithoutFee(factory, amountOut, path) : getAmountsIn(factory, amountOut, path);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PYESwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            IPYESwapPair pair = IPYESwapPair(pairFor(factory, path[i], path[i + 1]));
            address baseToken = pair.baseToken();
            uint totalFee = pair.getTotalFee();
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, baseToken != address(0), totalFee);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PYESwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            IPYESwapPair pair = IPYESwapPair(pairFor(factory, path[i - 1], path[i]));
            address baseToken = pair.baseToken();
            uint totalFee = pair.getTotalFee();
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, baseToken != address(0), totalFee);
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOutWithoutFee(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PYESwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, false, 0);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsInWithoutFee(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PYESwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, false, 0);
        }
    }

    function adminFeeCalculation(uint256 _amounts,uint256 _adminFee) internal pure returns (uint256,uint256) {
        uint adminFeeDeduct = (_amounts * _adminFee) / (10000);
        _amounts = _amounts - adminFeeDeduct;

        return (_amounts,adminFeeDeduct);
    }


    function checkIsExcluded(address account, address pairAddress) internal view returns (bool isExcluded) {
        IPYESwapPair pair = IPYESwapPair(pairAddress);
        address baseToken = pair.baseToken();

        if(baseToken == address(0)) {
            isExcluded = true;
        } else {
            address token0 = pair.token0();
            address token1 = pair.token1();

            IToken token = baseToken == token0 ? IToken(token1) : IToken(token0);
            try token.isExcludedFromFee(account) returns (bool isExcludedFromFee) {
                isExcluded = isExcludedFromFee;
            } catch {
                isExcluded = false;
            }

        }
    }

    function _calculateFees(address factory, address input, address output, uint amountIn, uint amount0Out, uint amount1Out, bool isExcluded) internal view returns (uint amount0Fee, uint amount1Fee) {
        IPYESwapPair pair = IPYESwapPair(pairFor(factory, input, output));
        (address token0,) = sortTokens(input, output);
        address baseToken = pair.baseToken();
        uint totalFee = pair.getTotalFee();
        amount0Fee = baseToken != token0 || isExcluded ? uint(0) : input == token0 ? (amountIn * totalFee) / (10**4) : (amount0Out * totalFee) / (10**4);
        amount1Fee = baseToken == token0 || isExcluded ? uint(0) : input != token0 ? (amountIn * totalFee) / (10**4) : (amount1Out * totalFee) / (10**4);
    }

    function _calculateAmounts(address factory, address input, address output, address token0, bool isExcluded) internal view returns (uint amountInput, uint amountOutput) {
        IPYESwapPair pair = IPYESwapPair(pairFor(factory, input, output));

        (uint reserve0, uint reserve1,, address baseToken) = pair.getReserves();
        uint totalFee = pair.getTotalFee();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput, baseToken != address(0) && !isExcluded, isExcluded ? 0 : totalFee);
    }
}
