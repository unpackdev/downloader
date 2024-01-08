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


contract QLiquidationV2 is WhitelistUpgradeable, ReentrancyGuardUpgradeable, IFlashLoanReceiver {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    IQore public constant Qore = IQore(0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48);
    IPriceCalculator public constant PriceCalculatorBSC = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IPancakeRouter02 private constant ROUTER_MDEX = IPancakeRouter02(0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8);

    address private constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;
    address private constant qBTC = 0xd055D32E50C57B413F7c2a4A052faF6933eA7927;
    address private constant qETH = 0xb4b77834C73E9f66de57e6584796b034D41Ce39A;
    address private constant qUSDC = 0x1dd6E079CF9a82c91DaF3D8497B27430259d32C2;
    address private constant qUSDT = 0x99309d2e7265528dC7C3067004cC4A90d37b7CC3;
    address private constant qDAI = 0x474010701715658fC8004f51860c90eEF4584D2B;
    address private constant qBUSD = 0xa3A155E76175920A40d2c8c765cbCB1148aeB9D1;
    address private constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address private constant qQBT = 0xcD2CD343CFbe284220677C78A08B1648bFa39865;
    address private constant qMDX = 0xFF858dB0d6aA9D3fCA13F6341a1693BE4416A550;

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;  // BUSD pair
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // BUSD pair
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    address private constant MDX = 0x9C65AB58d8d978DB963e63f2bfB7121627e3a739;


    /* ========== STATE VARIABLES ========== */

    mapping(address => address) private _routePairAddresses;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();

        for (uint i = 0; i < underlyingTokens().length; i++) {
            address underlying = underlyingTokens()[i];
            if (underlying != MDX && underlying != QBT) {
                IBEP20(underlying).approve(address(ROUTER), uint(- 1));
            }
            IBEP20(underlying).approve(qTokens()[i], uint(- 1));
            IBEP20(underlying).approve(address(Qore), uint(- 1));
        }

        IBEP20(WBNB).approve(address(ROUTER_MDEX), uint(- 1));
    }

    /* ========== VIEWS ========== */

    function underlyingTokens() public pure returns (address[10] memory) {
        return [WBNB, BTC, ETH, DAI, USDC, BUSD, USDT, CAKE, QBT, MDX];
    }

    function qTokens() public pure returns (address[10] memory) {
        return [qBNB, qBTC, qETH, qDAI, qUSDC, qBUSD, qUSDT, qCAKE, qQBT, qMDX];
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
            if (qTokenBorrowed == qMDX) {
                _swapToMDX(qTokenCollateral, amount.add(fees[0]));
            }
            else {
                _swapToRepayFlashloan(qTokenCollateral, qTokenBorrowed, amount.add(fees[0]));
            }
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

    function _swapToMDX(address _qTokenCollateral, uint repayAmount) private {
        address collateralToken = IQToken(_qTokenCollateral).underlying();
        if (collateralToken == WBNB) {
            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = MDX;
            ROUTER_MDEX.swapETHForExactTokens{value : address(this).balance}(repayAmount, path, address(this), block.timestamp);
        } else {
            uint WBNBamount;
            {
                address[] memory path = new address[](2);
                path[0] = WBNB;
                path[1] = MDX;
                WBNBamount = ROUTER_MDEX.getAmountsIn(repayAmount, path)[0];
            }

            if (_routePairAddresses[collateralToken] != address(0)) {
                address[] memory path = new address[](3);
                path[0] = collateralToken;
                path[1] = _routePairAddresses[collateralToken];
                path[2] = WBNB;

                ROUTER.swapTokensForExactTokens(WBNBamount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp)[2];
            } else {
                address[] memory path = new address[](2);
                path[0] = collateralToken;
                path[1] = WBNB;

                ROUTER.swapTokensForExactTokens(WBNBamount, IBEP20(collateralToken).balanceOf(address(this)), path, address(this), block.timestamp)[1];
            }

            address[] memory path = new address[](2);
            path[0] = WBNB;
            path[1] = MDX;

            ROUTER_MDEX.swapTokensForExactTokens(repayAmount, IBEP20(WBNB).balanceOf(address(this)), path, address(this), block.timestamp);
        }
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
            if ( (borrowedToken == ETH && (collateralToken == USDC || collateralToken == BTC)) ||
                (collateralToken == ETH && (borrowedToken == USDC || borrowedToken == BTC)) ||
                (borrowedToken == BTC && (collateralToken == ETH || collateralToken == BUSD)) ||
                (collateralToken == BTC && (borrowedToken == ETH || borrowedToken == BUSD)) ||
                (borrowedToken == DAI && collateralToken == BUSD) || (collateralToken == DAI && borrowedToken == BUSD) ||
                (borrowedToken == BUSD && (collateralToken == CAKE || collateralToken == BTC || collateralToken == USDT || collateralToken == USDC)) ||
                (collateralToken == BUSD && (borrowedToken == CAKE || borrowedToken == BTC || borrowedToken == USDT || borrowedToken == USDC)) ||
                (borrowedToken == USDT && (collateralToken == BUSD || collateralToken == CAKE || collateralToken == USDC)) ||
                (collateralToken == USDT && (borrowedToken == BUSD || borrowedToken == CAKE || borrowedToken == USDC)) ||
                (borrowedToken == USDC && (collateralToken == ETH || collateralToken == BUSD || collateralToken == USDT)) ||
                (collateralToken == USDC && (borrowedToken == ETH || borrowedToken == BUSD || borrowedToken == USDT)) ) {
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
