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
import "./IQToken.sol";
import "./IQValidator.sol";
import "./IFlashLoanReceiver.sol";
import "./SafeToken.sol";

import "./QoreAdmin.sol";

contract Qore is QoreAdmin {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint public constant FLASHLOAN_FEE = 5e14; // 0.05%

    /* ========== STATE VARIABLES ========== */

    mapping(address => address[]) public marketListOfUsers; // (account => qTokenAddress[])
    mapping(address => mapping(address => bool)) public usersOfMarket; // (qTokenAddress => (account => joined))
    address[] public totalUserList; // do not use

    mapping(address => uint) public supplyCap;

    /* ========== Event ========== */

    event SupplyCapUpdated(address indexed qToken, uint newSupplyCap);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Qore_init();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyMemberOfMarket(address qToken) {
        require(usersOfMarket[qToken][msg.sender], "Qore: must enter market");
        _;
    }

    modifier onlyMarket() {
        bool fromMarket = false;
        for (uint i = 0; i < markets.length; i++) {
            if (msg.sender == markets[i]) {
                fromMarket = true;
                break;
            }
        }
        require(fromMarket == true, "Qore: caller should be market");
        _;
    }

    /* ========== VIEWS ========== */

    function allMarkets() external view override returns (address[] memory) {
        return markets;
    }

    function marketInfoOf(address qToken) external view override returns (QConstant.MarketInfo memory) {
        return marketInfos[qToken];
    }

    function marketListOf(address account) external view override returns (address[] memory) {
        return marketListOfUsers[account];
    }

    function checkMembership(address account, address qToken) external view override returns (bool) {
        return usersOfMarket[qToken][account];
    }

    function accountLiquidityOf(address account) external view override returns (uint collateralInUSD, uint supplyInUSD, uint borrowInUSD) {
        return IQValidator(qValidator).getAccountLiquidity(account);
    }

    function distributionInfoOf(address market) external view override returns (QConstant.DistributionInfo memory) {
        return qDistributor.distributionInfoOf(market);
    }

    function accountDistributionInfoOf(address market, address account) external view override returns (QConstant.DistributionAccountInfo memory) {
        return qDistributor.accountDistributionInfoOf(market, account);
    }

    function apyDistributionOf(address market, address account) external view override returns (QConstant.DistributionAPY memory) {
        return qDistributor.apyDistributionOf(market, account);
    }

    function distributionSpeedOf(address qToken) external view override returns (uint supplySpeed, uint borrowSpeed) {
        QConstant.DistributionInfo memory distribution = qDistributor.distributionInfoOf(qToken);
        return (distribution.supplySpeed, distribution.borrowSpeed);
    }

    function boostedRatioOf(address market, address account) external view override returns (uint boostedSupplyRatio, uint boostedBorrowRatio) {
        return qDistributor.boostedRatioOf(market, account);
    }

    function accruedQubit(address account) external view override returns (uint) {
        return qDistributor.accruedQubit(markets, account);
    }

    function accruedQubit(address market, address account) external view override returns (uint) {
        address[] memory _markets = new address[](1);
        _markets[0] = market;
        return qDistributor.accruedQubit(_markets, account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function enterMarkets(address[] memory qTokens) public override {
        for (uint i = 0; i < qTokens.length; i++) {
            _enterMarket(payable(qTokens[i]), msg.sender);
        }
    }

    function exitMarket(address qToken) external override onlyListedMarket(qToken) onlyMemberOfMarket(qToken) {
        QConstant.AccountSnapshot memory snapshot = IQToken(qToken).accruedAccountSnapshot(msg.sender);
        require(snapshot.borrowBalance == 0, "Qore: borrow balance must be zero");
        require(
            IQValidator(qValidator).redeemAllowed(qToken, msg.sender, snapshot.qTokenBalance),
            "Qore: cannot redeem"
        );

        _removeUserMarket(qToken, msg.sender);
        emit MarketExited(qToken, msg.sender);
    }

    function supply(address qToken, uint uAmount)
        external
        payable
        override
        onlyListedMarket(qToken)
        nonReentrant
        returns (uint)
    {
        uAmount = IQToken(qToken).underlying() == address(WBNB) ? msg.value : uAmount;

        if (supplyCap[qToken] != 0) {
            require(IQToken(qToken).totalSupply().mul(IQToken(qToken).exchangeRate())
            .div(1e18).add(uAmount) <= supplyCap[qToken], "Qore: market supply cap reached");
        }
        uint qAmount = IQToken(qToken).supply{ value: msg.value }(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return qAmount;
    }

    function redeemToken(address qToken, uint qAmount)
        external
        override
        onlyListedMarket(qToken)
        nonReentrant
        returns (uint)
    {
        uint uAmountRedeem = IQToken(qToken).redeemToken(msg.sender, qAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function redeemUnderlying(address qToken, uint uAmount)
        external
        override
        onlyListedMarket(qToken)
        nonReentrant
        returns (uint)
    {
        uint uAmountRedeem = IQToken(qToken).redeemUnderlying(msg.sender, uAmount);
        qDistributor.notifySupplyUpdated(qToken, msg.sender);

        return uAmountRedeem;
    }

    function borrow(address qToken, uint amount) external override onlyListedMarket(qToken) nonReentrant {
        _enterMarket(qToken, msg.sender);
        require(IQValidator(qValidator).borrowAllowed(qToken, msg.sender, amount), "Qore: cannot borrow");

        IQToken(payable(qToken)).borrow(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrow(address qToken, uint amount) external payable override onlyListedMarket(qToken) nonReentrant {
        IQToken(payable(qToken)).repayBorrow{ value: msg.value }(msg.sender, amount);
        qDistributor.notifyBorrowUpdated(qToken, msg.sender);
    }

    function repayBorrowBehalf(
        address qToken,
        address borrower,
        uint amount
    ) external payable override onlyListedMarket(qToken) nonReentrant {
        IQToken(payable(qToken)).repayBorrowBehalf{ value: msg.value }(msg.sender, borrower, amount);
        qDistributor.notifyBorrowUpdated(qToken, borrower);
    }

    function liquidateBorrow(
        address qTokenBorrowed,
        address qTokenCollateral,
        address borrower,
        uint amount
    ) external payable override nonReentrant {
        amount = IQToken(qTokenBorrowed).underlying() == address(WBNB) ? msg.value : amount;
        require(marketInfos[qTokenBorrowed].isListed && marketInfos[qTokenCollateral].isListed, "Qore: invalid market");
        require(usersOfMarket[qTokenCollateral][borrower], "Qore: not a collateral");
        require(marketInfos[qTokenCollateral].collateralFactor > 0, "Qore: not a collateral");
        require(
            IQValidator(qValidator).liquidateAllowed(qTokenBorrowed, borrower, amount, closeFactor),
            "Qore: cannot liquidate borrow"
        );

        uint qAmountToSeize = IQToken(qTokenBorrowed).liquidateBorrow{ value: msg.value }(
            qTokenCollateral,
            msg.sender,
            borrower,
            amount
        );
        IQToken(qTokenCollateral).seize(msg.sender, borrower, qAmountToSeize);
        qDistributor.notifyTransferred(qTokenCollateral, borrower, msg.sender);
        qDistributor.notifyBorrowUpdated(qTokenBorrowed, borrower);
    }

    function claimQubit() external override nonReentrant {
        qDistributor.claimQubit(markets, msg.sender);
    }

    function claimQubit(address market) external override nonReentrant {
        address[] memory _markets = new address[](1);
        _markets[0] = market;
        qDistributor.claimQubit(_markets, msg.sender);
    }

    function transferTokens(address spender, address src, address dst, uint amount) external override nonReentrant onlyMarket {
        IQToken(msg.sender).transferTokensInternal(spender, src, dst, amount);
        qDistributor.notifyTransferred(msg.sender, src, dst);
    }

    /* ========== RESTRICTED FUNCTION ========== */

    function setSupplyCap(address qToken, uint newSupplyCap) external onlyKeeper {
        supplyCap[qToken] = newSupplyCap;
        emit SupplyCapUpdated(qToken, newSupplyCap);
    }

    /* ========== RESTRICTED FUNCTION FOR WHITELIST ========== */

    function supplyAndBorrowBehalf(address account, address supplyMarket, uint supplyAmount, address borrowMarket, uint borrowAmount)
        external
        payable
        override
        onlyListedMarket(supplyMarket)
        onlyListedMarket(borrowMarket)
        onlyWhitelisted
        nonReentrant
        returns (uint)
    {
        address underlying = IQToken(supplyMarket).underlying();
        uint uAmount = underlying == address(WBNB) ? msg.value : supplyAmount;

        uint qAmount = IQToken(supplyMarket).supplyBehalf{ value: msg.value }(msg.sender, account, uAmount);

        _enterMarket(supplyMarket, account);

        require(_borrowAllowed(supplyMarket, supplyAmount, borrowMarket, borrowAmount), "Qore: cannot borrow");
        IQToken(borrowMarket).borrow(account, borrowAmount);

        qDistributor.notifySupplyUpdated(supplyMarket, account);
        qDistributor.notifyBorrowUpdated(borrowMarket, account);
        return qAmount;
    }

    function supplyAndBorrowBNB(address account, address supplyMarket, uint supplyAmount, uint borrowAmount)
        external
        payable
        override
        onlyListedMarket(supplyMarket)
        onlyWhitelisted
        nonReentrant
        returns (uint)
    {
        require(borrowAmount <= 5e16, "exceed maximum amount");
        address underlying = IQToken(supplyMarket).underlying();
        uint uAmount = underlying == address(WBNB) ? msg.value : supplyAmount;
        uint qAmount = IQToken(supplyMarket).supplyBehalf{ value: msg.value }(msg.sender, account, uAmount);

        _enterMarket(supplyMarket, account);

        address qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;
        _enterMarket(qBNB, account);

        require(_borrowAllowed(supplyMarket, supplyAmount, qBNB, borrowAmount), "Qore: cannot borrow");
        IQToken(qBNB).borrow(account, borrowAmount);
        // no reward update to reduce gasfee
        // qDistributor.notifySupplyUpdated(supplyMarket, account);
        // qDistributor.notifyBorrowUpdated(0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351, account);

        return qAmount;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _enterMarket(address qToken, address _account) internal onlyListedMarket(qToken) {
        if (!usersOfMarket[qToken][_account]) {
            usersOfMarket[qToken][_account] = true;
            marketListOfUsers[_account].push(qToken);
            emit MarketEntered(qToken, _account);
        }
    }

    function _removeUserMarket(address qTokenToExit, address _account) private {
        require(marketListOfUsers[_account].length > 0, "Qore: cannot pop user market");
        delete usersOfMarket[qTokenToExit][_account];

        uint length = marketListOfUsers[_account].length;
        for (uint i = 0; i < length; i++) {
            if (marketListOfUsers[_account][i] == qTokenToExit) {
                marketListOfUsers[_account][i] = marketListOfUsers[_account][length - 1];
                marketListOfUsers[_account].pop();
                break;
            }
        }
    }

    function _borrowAllowed(address supplyMarket, uint supplyAmount, address borrowMarket, uint borrowAmount) internal view returns (bool){
        // Borrow cap of 0 corresponds to unlimited borrowing
        uint borrowCap = marketInfos[borrowMarket].borrowCap;
        if (borrowCap != 0) {
            uint totalBorrows = IQToken(payable(borrowMarket)).totalBorrow();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "Qore: market borrow cap reached");
        }

        address[] memory markets = new address[](2);
        markets[0] = supplyMarket;
        markets[1] = borrowMarket;
        uint[] memory prices = priceCalculator.getUnderlyingPrices(markets);
        uint collateralValueInUSD = prices[0].mul(supplyAmount).mul(marketInfos[supplyMarket].collateralFactor).div(1e36);
        uint borrowValueInUSD = prices[1].mul(borrowAmount).div(1e18);

        return collateralValueInUSD >= borrowValueInUSD;
    }
}
