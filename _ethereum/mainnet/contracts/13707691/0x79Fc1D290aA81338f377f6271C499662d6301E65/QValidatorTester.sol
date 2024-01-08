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

import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";

import "./IPriceCalculator.sol";
import "./IQValidator.sol";
import "./IQToken.sol";
import "./IQore.sol";
import "./QConstant.sol";

contract QValidatorTester is IQValidator, OwnableUpgradeable {
    using SafeMath for uint;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant BNB = 0x0000000000000000000000000000000000000000;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /* ========== STATE VARIABLES ========== */

    IQore public qore;
    IPriceCalculator oracle;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== VIEWS ========== */

    function getAccountLiquidity(address account) external view override returns (uint collateralInUSD, uint supplyInUSD, uint borrowInUSD) {
        collateralInUSD = 0;
        borrowInUSD = 0;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accountSnapshot(account);

            uint collateralFactor = qore.marketInfoOf(payable(assets[i])).collateralFactor;
            uint collateralValuePerShareInUSD = snapshot.exchangeRate.mul(prices[i]).mul(collateralFactor).div(1e36);

            collateralInUSD = collateralInUSD.add(snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18));
            supplyInUSD = supplyInUSD.add(snapshot.qTokenBalance.mul(snapshot.exchangeRate).mul(prices[i]).div(1e36));
            borrowInUSD = borrowInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setQore(address _qore) external onlyOwner {
        require(_qore != address(0), "QValidator: invalid qore address");
        require(address(qore) == address(0), "QValidator: qore already set");
        qore = IQore(_qore);
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "QValidator: invalid oracle address");
        oracle = IPriceCalculator(_oracle);
    }

    /* ========== ALLOWED FUNCTIONS ========== */

    function redeemAllowed(
        address qToken,
        address redeemer,
        uint redeemAmount
    ) external override returns (bool) {
        (, uint shortfall) = _getAccountLiquidityInternal(redeemer, qToken, redeemAmount, 0);
        return shortfall == 0;
    }

    function borrowAllowed(
        address qToken,
        address borrower,
        uint borrowAmount
    ) external override returns (bool) {
        require(qore.checkMembership(borrower, address(qToken)), "QValidator: enterMarket required");
        require(oracle.getUnderlyingPrice(address(qToken)) > 0, "QValidator: Underlying price error");

        // Borrow cap of 0 corresponds to unlimited borrowing
        uint borrowCap = qore.marketInfoOf(qToken).borrowCap;
        if (borrowCap != 0) {
            uint totalBorrows = IQToken(payable(qToken)).accruedTotalBorrow();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "QValidator: market borrow cap reached");
        }

        (, uint shortfall) = _getAccountLiquidityInternal(borrower, qToken, 0, borrowAmount);
        return shortfall == 0;
    }

    function liquidateAllowed(
        address qToken,
        address borrower,
        uint liquidateAmount,
        uint closeFactor
    ) external override returns (bool) {
        // The borrower must have shortfall in order to be liquidate
        (, uint shortfall) = _getAccountLiquidityInternal(borrower, address(0), 0, 0);
        require(shortfall != 0, "QValidator: Insufficient shortfall");

        // The liquidator may not repay more than what is allowed by the closeFactor
        uint borrowBalance = IQToken(payable(qToken)).accruedBorrowBalanceOf(borrower);
        uint maxClose = closeFactor.mul(borrowBalance).div(1e18);
        return liquidateAmount <= maxClose;
    }

    function qTokenAmountToSeize(
        address qTokenBorrowed,
        address qTokenCollateral,
        uint amount
    ) external override returns (uint seizeQAmount) {
        uint priceBorrowed = oracle.getUnderlyingPrice(qTokenBorrowed);
        uint priceCollateral = oracle.getUnderlyingPrice(qTokenCollateral);
        require(priceBorrowed != 0 && priceCollateral != 0, "QValidator: price error");

        uint exchangeRate = IQToken(payable(qTokenCollateral)).accruedExchangeRate();
        require(exchangeRate != 0, "QValidator: exchangeRate of qTokenCollateral is zero");

        // seizeQTokenAmount = amount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
        return amount.mul(qore.liquidationIncentive()).mul(priceBorrowed).div(priceCollateral.mul(exchangeRate));
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getAccountLiquidityInternal(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) private returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accruedAccountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));

            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }

    function getAccountLiquidityTester(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) external returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;

        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = getUnderlyingPricesTester(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accruedAccountSnapshot(account);

            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));

            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }

        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }

    function getUnderlyingPricesTester(address[] memory assets) public view returns (uint[] memory) {
        uint[] memory returnValue = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            IQToken qToken = IQToken(payable(assets[i]));
            address addr = qToken.underlying();
            if (addr == USDT) {
                returnValue[i] = 1e18;
            } else if (addr == BUNNY) {
                returnValue[i] = 25e18;
            } else if (addr == CAKE) {
                returnValue[i] = 20e18;
            } else if (addr == BUSD) {
                returnValue[i] = 1e18;
            } else if (addr == USDT) {
                returnValue[i] = 1e18;
            } else if (addr == BNB || addr == WBNB) {
                returnValue[i] = 400e18;
            } else {
                returnValue[i] = 0;
            }
        }
        return returnValue;
    }
}
