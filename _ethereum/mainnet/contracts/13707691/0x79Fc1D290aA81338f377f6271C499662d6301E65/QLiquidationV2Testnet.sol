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

import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./SafeToken.sol";
import "./WhitelistUpgradeable.sol";

import "./IBEP20.sol";
import "./IPancakePair.sol";
import "./IPancakeRouter02.sol";
import "./IQore.sol";
import "./IQToken.sol";
import "./IWETH.sol";
import "./IPriceCalculator.sol";
import "./IFlashLoanReceiver.sol";


contract QLiquidationV2Testnet is WhitelistUpgradeable, ReentrancyGuardUpgradeable, IFlashLoanReceiver {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    IQore public constant Qore = IQore(0x995cCA2cD0C269fdEe7d057A8A7aaA1586ecEf51);
    IPriceCalculator public constant PriceCalculatorBSC = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

    address private constant qBNB = 0x14fA6A83A08B763B8A430e1fAeafe009D266F280;
    address private constant qETH = 0xAf9A0488D21A3cec2012f3E6Fe632B65Aa6Ea61D;
    address private constant qUSDT = 0x93848E23F0a70891A67a98a6CEBb47Fa55A51508;
    address private constant qDAI = 0xfc743504c7FF5526e3Ba97617F6e6Bf8fD8cfdF0;
    address private constant qBUSD = 0x5B8BA405976b3A798F47DAE502e1982502aF64c5;
    address private constant qQBT = 0x2D076EC4FE501927c5bea2A5bA8902e5e7A9B727;

    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    address private constant ETH = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca;
    address private constant DAI = 0x8a9424745056Eb399FD19a0EC26A14316684e274;  // BUSD pair
    address private constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address private constant USDT = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;


    address private constant QBT = 0xF523e4478d909968090a232eB380E2dd6f802518;



    /* ========== STATE VARIABLES ========== */

    mapping(address => address) private _routePairAddresses;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();

        for (uint i = 0; i < underlyingTokens().length; i++) {
            address underlying = underlyingTokens()[i];
            if (underlying != QBT) {
                IBEP20(underlying).approve(address(ROUTER), uint(- 1));
            }
            IBEP20(underlying).approve(qTokens()[i], uint(- 1));
            IBEP20(underlying).approve(address(Qore), uint(- 1));
        }

    }

    /* ========== VIEWS ========== */

    function underlyingTokens() public pure returns (address[6] memory) {
        return [WBNB, ETH, DAI, BUSD, USDT, QBT];
    }

    function qTokens() public pure returns (address[6] memory) {
        return [qBNB, qETH, qDAI, qBUSD, qUSDT, qQBT];
    }

    /* ========== RESTRICTED FUNCTION ========== */

    function setRoutePairAddress(address token, address route) external onlyOwner {
        require(route != address(0), "QLiquidation: invalid route address");
        _routePairAddresses[token] = route;
    }

    /* ========== Flashloan Callback FUNCTION ========== */

    function executeOperation(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata fees,
        address,
        bytes calldata params
    ) external override returns (bool) {
        require(fees.length == 1, "QLiquidationV2 : invalid request");
        (address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) = abi.decode(params, (address, address, address, uint));

        _liquidate(qTokenBorrowed, qTokenCollateral, borrower, amount);

        if (qTokenBorrowed != qTokenCollateral) {
            _swapToRepayFlashloan(qTokenCollateral, qTokenBorrowed, amount.add(fees[0]));
        }
        else if (qTokenBorrowed == qBNB) {
            IWETH(WBNB).deposit{value:amount.add(fees[0])}();
        }

        return true;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function liquidate(address qTokenBorrowed, address qTokenCollateral, address borrow, uint amount) external onlyWhitelisted nonReentrant {
        _flashloanQubit(qTokenBorrowed, qTokenCollateral, borrow, amount);
    }

    function autoLiquidate(address account) external onlyWhitelisted nonReentrant {
        (uint collateralInUSD, , uint borrowInUSD) = Qore.accountLiquidityOf(account);
        require(borrowInUSD > collateralInUSD, "QLiquidation: Insufficient shortfall");

        (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) = _getTargetMarkets(account);
        _flashloanQubit(qTokenBorrowed, qTokenCollateral, account, liquidateAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _liquidate(address qTokenBorrowed, address qTokenCollateral, address borrower, uint amount) private {
        uint qTokenCollateralBalance = IQToken(qTokenCollateral).balanceOf(address(this));
        if (IQToken(qTokenBorrowed).underlying() == WBNB) {
            Qore.liquidateBorrow{value : amount}(qTokenBorrowed, qTokenCollateral, borrower, 0);
        } else {
            Qore.liquidateBorrow(qTokenBorrowed, qTokenCollateral, borrower, amount);
        }

        _redeemToken(qTokenCollateral, IQToken(qTokenCollateral).balanceOf(address(this)).sub(qTokenCollateralBalance));
    }

    function _getTargetMarkets(address account) private view returns (address qTokenBorrowed, address qTokenCollateral, uint liquidateAmount) {
        uint maxSupplied;
        uint maxBorrowed;
        address[] memory markets = Qore.marketListOf(account);
        for (uint i = 0; i < markets.length; i++) {
            uint borrow = IQToken(markets[i]).borrowBalanceOf(account);
            uint supply = IQToken(markets[i]).underlyingBalanceOf(account);

            if (borrow > 0 && borrow > maxBorrowed) {
                maxBorrowed = borrow;
                qTokenBorrowed = markets[i];
            }

            uint collateralFactor = Qore.marketInfoOf(markets[i]).collateralFactor;
            if (collateralFactor > 0 && supply > 0 && supply > maxSupplied) {
                maxSupplied = supply;
                qTokenCollateral = markets[i];
            }
        }
        liquidateAmount = _getAvailableAmounts(qTokenBorrowed, qTokenCollateral, maxBorrowed, maxSupplied);
        return (qTokenBorrowed, qTokenCollateral, liquidateAmount);
    }

    function _getAvailableAmounts(address qTokenBorrowed, address qTokenCollateral, uint borrowAmount, uint supplyAmount) private view returns (uint closeAmount) {
        uint borrowPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenBorrowed);
        uint supplyPrice = PriceCalculatorBSC.getUnderlyingPrice(qTokenCollateral);
        require(supplyPrice != 0 && borrowPrice != 0, "QLiquidation: price error");

        uint borrowValue = borrowPrice.mul(borrowAmount).div(1e18);
        uint supplyValue = supplyPrice.mul(supplyAmount).div(1e18);

        uint maxCloseValue = borrowValue.mul(Qore.closeFactor()).div(1e18);
        uint maxCloseValueWithIncentive = maxCloseValue.mul(110).div(100);
        return closeAmount = maxCloseValueWithIncentive < supplyValue ? maxCloseValue.mul(1e18).div(borrowPrice)
                                                                      : supplyValue.mul(90).div(100).mul(1e18).div(borrowPrice);
    }

    function _flashloanQubit(address _qTokenBorrowed, address _qTokenCollateral, address borrower, uint amount) private {
        address[] memory _markets = new address[](1);
        _markets[0] = _qTokenBorrowed;

        uint[] memory _amounts = new uint[](1);
        _amounts[0] = amount;
//        Qore.flashLoan(address(this), _markets, _amounts,
//            abi.encode(_qTokenBorrowed, _qTokenCollateral, borrower, amount)
//        );
    }

    function _redeemToken(address _qTokenCollateral, uint amount) private returns (uint) {
        IBEP20 collateralToken = IBEP20(IQToken(_qTokenCollateral).underlying());

        uint collateralBalance = collateralToken.balanceOf(address(this));
        Qore.redeemToken(_qTokenCollateral, amount);

        return collateralToken.balanceOf(address(this)).sub(collateralBalance);
    }

    function _swapToRepayFlashloan(address _qTokenCollateral, address _qTokenBorrowed, uint repayAmount) private {
        address collateralToken = IQToken(_qTokenCollateral).underlying();
        address borrowedToken = IQToken(_qTokenBorrowed).underlying();

        if (collateralToken == WBNB) {
            if (_routePairAddresses[borrowedToken] != address(0)) {
                address[] memory path = new address[](3);
                path[0] = WBNB;
                path[1] = _routePairAddresses[borrowedToken];
                path[2] = borrowedToken;
                ROUTER.swapETHForExactTokens{value : address(this).balance}(repayAmount, path, address(this), block.timestamp);
            }
            else {
                address[] memory path = new address[](2);
                path[0] = WBNB;
                path[1] = borrowedToken;
                ROUTER.swapETHForExactTokens{value : address(this).balance}(repayAmount, path, address(this), block.timestamp);
            }
        } else if (borrowedToken == WBNB) {
            if (_routePairAddresses[collateralToken] != address(0)) {
                address[] memory path = new address[](3);
                path[0] = collateralToken;
                path[1] = _routePairAddresses[collateralToken];
                path[2] = WBNB;

                ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
            } else {
                address[] memory path = new address[](2);
                path[0] = collateralToken;
                path[1] = WBNB;

                ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
            }
        }
        else {
            if ( (borrowedToken == DAI && collateralToken == BUSD) || (collateralToken == DAI && borrowedToken == BUSD) ||
                (borrowedToken == BUSD && (collateralToken == USDT)) ||
                (collateralToken == BUSD && (borrowedToken == USDT)) ||
                (borrowedToken == USDT && (collateralToken == BUSD)) ||
                (collateralToken == USDT && (borrowedToken == BUSD)) ) {
                address[] memory path = new address[](2);
                path[0] = collateralToken;
                path[1] = borrowedToken;

                ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
            } else {
                // first swap to WBNB,
                uint WBNBamount;
                if (_routePairAddresses[borrowedToken] != address(0)) {
                    address[] memory path = new address[](3);
                    path[0] = WBNB;
                    path[1] = _routePairAddresses[borrowedToken];
                    path[2] = borrowedToken;

                    WBNBamount = ROUTER.getAmountsIn(repayAmount, path)[0];
                } else {
                    address[] memory path = new address[](2);
                    path[0] = WBNB;
                    path[1] = borrowedToken;

                    WBNBamount = ROUTER.getAmountsIn(repayAmount, path)[0];
                }

                if (_routePairAddresses[collateralToken] != address(0)) {
                    address[] memory path = new address[](3);
                    path[0] = collateralToken;
                    path[1] = _routePairAddresses[collateralToken];
                    path[2] = WBNB;

                    ROUTER.swapTokensForExactTokens(WBNBamount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
                } else {
                    address[] memory path = new address[](2);
                    path[0] = collateralToken;
                    path[1] = WBNB;

                    ROUTER.swapTokensForExactTokens(WBNBamount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp);
                }

                // then swap WBNB to borrowedToken
                if (_routePairAddresses[borrowedToken] != address(0)) {
                    address[] memory path = new address[](3);
                    path[0] = WBNB;
                    path[1] = _routePairAddresses[borrowedToken];
                    path[2] = borrowedToken;

                    ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(WBNB).balanceOf(address(this)), path, address(this), block.timestamp);
                } else {
                    address[] memory path = new address[](2);
                    path[0] = WBNB;
                    path[1] = borrowedToken;

                    ROUTER.swapTokensForExactTokens(repayAmount, IBEP20(WBNB).balanceOf(address(this)), path, address(this), block.timestamp);
                }
            }
        }
    }
}
