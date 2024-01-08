// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
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
* SOFTWARE.
*/

import "./IQToken.sol";



contract SimplePriceCalculatorTester {
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address public constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address public constant BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address public constant MDX = 0x9C65AB58d8d978DB963e63f2bfB7121627e3a739;

    uint public priceBunny;
    uint public priceCake;
    uint public priceBNB;
    uint public priceETH;
    uint public priceBTC;
    uint public priceMDX;

    constructor() public {
        priceBunny = 20e18;
        priceCake = 15e18;
        priceBNB = 400e18;
        priceETH = 3000e18;
        priceBTC = 40000e18;
        priceMDX = 142e16;
    }

    function setUnderlyingPrice(address qTokenAddress, uint price) public {
        IQToken qToken = IQToken(qTokenAddress);
        address addr = qToken.underlying();
        if (addr == BUNNY) {
            priceBunny = price;
        } else if (addr == CAKE) {
            priceCake = price;
        } else if (addr == BNB || addr == WBNB) {
            priceBNB = price;
        } else if (addr == ETH) {
            priceETH = price;
        } else if (addr == BTC) {
            priceBTC = price;
        } else if (addr == MDX) {
            priceMDX = price;
        }
    }

    function getUnderlyingPrice(address qTokenAddress) public view returns (uint) {
        IQToken qToken = IQToken(qTokenAddress);
        address addr = qToken.underlying();
        if (addr == BUNNY) {
            return priceBunny;
        } else if (addr == CAKE) {
            return priceCake;
        } else if (addr == BUSD) {
            return 1e18;
        } else if (addr == USDT || addr == USDC || addr == DAI) {
            return 1e18;
        } else if (addr == ETH) {
            return priceETH;
        } else if (addr == BTC) {
            return priceBTC;
        } else if (addr == MDX) {
            return priceMDX;
        } else if (addr == BNB || addr == WBNB) {
            return priceBNB;
        } else {
            return 0;
        }
    }

    function getUnderlyingPrices(address[] memory assets) public view returns (uint[] memory) {
        uint[] memory returnValue = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            IQToken qToken = IQToken(payable(assets[i]));
            address addr = qToken.underlying();
            if (addr == BUNNY) {
                returnValue[i] = priceBunny;
            } else if (addr == CAKE) {
                returnValue[i] = priceCake;
            } else if (addr == BUSD || addr == USDC || addr == DAI) {
                returnValue[i] = 1e18;
            } else if (addr == USDT) {
                returnValue[i] = 1e18;
            } else if (addr == BNB || addr == WBNB) {
                returnValue[i] = priceBNB;
            } else if (addr == ETH) {
                returnValue[i] = priceETH;
            } else if (addr == BTC) {
                returnValue[i] = priceBTC;
            } else if (addr == MDX) {
                returnValue[i] = priceMDX;
            } else {
                returnValue[i] = 0;
            }
        }
        return returnValue;
    }
}
