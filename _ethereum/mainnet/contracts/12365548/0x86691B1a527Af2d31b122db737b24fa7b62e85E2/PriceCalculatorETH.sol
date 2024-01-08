// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./AggregatorV3Interface.sol";
import "./IPriceCalculator.sol";


contract PriceCalculatorETH is IPriceCalculator, OwnableUpgradeable {
    using SafeMath for uint;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    AggregatorV3Interface private constant ethPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    AggregatorV3Interface private constant bnbPriceFeed = AggregatorV3Interface(0x14e613AC84a31f709eadbdF89C6CC390fDc9540A);

    /* ========== STATE VARIABLES ========== */

    mapping(address => address) private pairTokens;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== Restricted Operation ========== */

    function setPairToken(address asset, address pairToken) public onlyOwner {
        pairTokens[asset] = pairToken;
    }

    /* ========== Value Calculation ========== */

    function priceOfETH() view public returns (uint) {
        (, int price, , ,) = ethPriceFeed.latestRoundData();
        return uint(price).mul(1e10);
    }

    function priceOfBNB() view public returns (uint) {
        (, int price, , ,) = bnbPriceFeed.latestRoundData();
        return uint(price).mul(1e10);
    }

    function pricesInUSD(address[] memory assets) public view override returns (uint[] memory) {
        uint[] memory prices = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            (, uint valueInUSD) = valueOfAsset(assets[i], 1e18);
            prices[i] = valueInUSD;
        }
        return prices;
    }

    function valueOfAsset(address asset, uint amount) public view override returns (uint valueInETH, uint valueInUSD) {
        if (asset == address(0) || asset == WETH) {
            valueInETH = amount;
            valueInUSD = amount.mul(priceOfETH()).div(1e18);
        }
        else if (keccak256(abi.encodePacked(IUniswapV2Pair(asset).symbol())) == keccak256("UNI-V2")) {
            if (IUniswapV2Pair(asset).totalSupply() == 0) return (0, 0);

            (uint reserve0, uint reserve1, ) = IUniswapV2Pair(asset).getReserves();
            if (IUniswapV2Pair(asset).token0() == WETH) {
                valueInETH = amount.mul(reserve0).mul(2).div(IUniswapV2Pair(asset).totalSupply());
            } else if (IUniswapV2Pair(asset).token1() == WETH) {
                valueInETH = amount.mul(reserve1).mul(2).div(IUniswapV2Pair(asset).totalSupply());
            } else {
                (uint token0PriceInETH,) = valueOfAsset(IUniswapV2Pair(asset).token0(), 1e18);
                valueInETH = amount.mul(reserve0).mul(2).mul(token0PriceInETH).div(1e18).div(IUniswapV2Pair(asset).totalSupply());
            }
            valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
        }
        else {
            uint decimalModifier = uint(ERC20(asset).decimals()) < 18 ? 18 - uint(ERC20(asset).decimals()) : 0;
            address pairToken = pairTokens[asset] == address(0) ? WETH : pairTokens[asset];
            address pair = factory.getPair(asset, pairToken);
            if (IERC20(asset).balanceOf(pair) == 0) return (0, 0);

            (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pair).getReserves();
            if (IUniswapV2Pair(pair).token0() == pairToken) {
                valueInETH = reserve0.mul(amount).div(reserve1).div(10 ** decimalModifier);
            } else if (IUniswapV2Pair(pair).token1() == pairToken) {
                valueInETH = reserve1.mul(amount).div(reserve0).div(10 ** decimalModifier);
            } else {
                return (0, 0);
            }

            if (pairToken != WETH) {
                (uint pairValueInETH,) = valueOfAsset(pairToken, 1e18);
                valueInETH = valueInETH.mul(pairValueInETH).div(1e18);
            }
            valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
        }
    }
}
