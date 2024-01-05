// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./Fund.sol";
import "./Lending.sol";
import "./RoleAware.sol";
import "./CrossMarginLiquidation.sol";

// Goal: all external functions only accessible to margintrader role
// except for view functions of course

contract CrossMarginTrading is CrossMarginLiquidation, IMarginTrading {
    constructor(address _peg, address _roles)
        RoleAware(_roles)
        PriceAware(_peg)
    {}

    /// @dev admin function to set the token cap
    function setTokenCap(address token, uint256 cap)
        external
        onlyOwnerExecActivator
    {
        tokenCaps[token] = cap;
    }

    /// @dev setter for cooling off period for withdrawing funds after deposit
    function setCoolingOffPeriod(uint256 blocks) external onlyOwnerExec {
        coolingOffPeriod = blocks;
    }

    /// @dev admin function to set leverage
    function setLeveragePercent(uint256 _leveragePercent)
        external
        onlyOwnerExec
    {
        leveragePercent = _leveragePercent;
    }

    /// @dev admin function to set liquidation threshold
    function setLiquidationThresholdPercent(uint256 threshold)
        external
        onlyOwnerExec
    {
        liquidationThresholdPercent = threshold;
    }

    /// @dev gets called by router to affirm a deposit to an account
    function registerDeposit(
        address trader,
        address token,
        uint256 depositAmount
    ) external override returns (uint256 extinguishableDebt) {
        require(isMarginTrader(msg.sender), "Calling contr. not authorized");

        CrossMarginAccount storage account = marginAccounts[trader];
        account.lastDepositBlock = block.number;

        if (account.borrowed[token] > 0) {
            extinguishableDebt = min(depositAmount, account.borrowed[token]);
            extinguishDebt(account, token, extinguishableDebt);
            totalShort[token] -= extinguishableDebt;
        }

        // no overflow because depositAmount >= extinguishableDebt
        uint256 addedHolding = depositAmount - extinguishableDebt;
        _registerDeposit(account, token, addedHolding);
    }

    function _registerDeposit(
        CrossMarginAccount storage account,
        address token,
        uint256 addedHolding
    ) internal {
        addHolding(account, token, addedHolding);

        totalLong[token] += addedHolding;
        require(
            tokenCaps[token] >= totalLong[token],
            "Exceeds global token cap"
        );
    }

    /// @dev gets called by router to affirm borrowing event
    function registerBorrow(
        address trader,
        address borrowToken,
        uint256 borrowAmount
    ) external override {
        require(isMarginTrader(msg.sender), "Calling contr. not authorized");
        CrossMarginAccount storage account = marginAccounts[trader];
        addHolding(account, borrowToken, borrowAmount);
        _registerBorrow(account, borrowToken, borrowAmount);
    }

    function _registerBorrow(
        CrossMarginAccount storage account,
        address borrowToken,
        uint256 borrowAmount
    ) internal {
        totalShort[borrowToken] += borrowAmount;
        totalLong[borrowToken] += borrowAmount;
        require(
            tokenCaps[borrowToken] >= totalShort[borrowToken] &&
                tokenCaps[borrowToken] >= totalLong[borrowToken],
            "Exceeds global token cap"
        );

        borrow(account, borrowToken, borrowAmount);
    }

    /// @dev gets called by router to affirm withdrawal of tokens from account
    function registerWithdrawal(
        address trader,
        address withdrawToken,
        uint256 withdrawAmount
    ) external override {
        require(isMarginTrader(msg.sender), "Calling contr not authorized");
        CrossMarginAccount storage account = marginAccounts[trader];
        _registerWithdrawal(account, withdrawToken, withdrawAmount);
    }

    function _registerWithdrawal(
        CrossMarginAccount storage account,
        address withdrawToken,
        uint256 withdrawAmount
    ) internal {
        require(
            block.number > account.lastDepositBlock + coolingOffPeriod,
            "No withdrawal soon after deposit"
        );

        totalLong[withdrawToken] -= withdrawAmount;
        // throws on underflow
        account.holdings[withdrawToken] =
            account.holdings[withdrawToken] -
            withdrawAmount;
        require(positiveBalance(account), "Insufficient balance");
    }

    /// @dev overcollateralized borrowing on a cross margin account, called by router
    function registerOvercollateralizedBorrow(
        address trader,
        address depositToken,
        uint256 depositAmount,
        address borrowToken,
        uint256 withdrawAmount
    ) external override {
        require(isMarginTrader(msg.sender), "Calling contr. not authorized");

        CrossMarginAccount storage account = marginAccounts[trader];

        _registerDeposit(account, depositToken, depositAmount);
        _registerBorrow(account, borrowToken, withdrawAmount);
        _registerWithdrawal(account, borrowToken, withdrawAmount);

        account.lastDepositBlock = block.number;
    }

    /// @dev gets called by router to register a trade and borrow and extinguish as necessary
    function registerTradeAndBorrow(
        address trader,
        address tokenFrom,
        address tokenTo,
        uint256 inAmount,
        uint256 outAmount
    )
        external
        override
        returns (uint256 extinguishableDebt, uint256 borrowAmount)
    {
        require(isMarginTrader(msg.sender), "Calling contr. not an authorized");

        CrossMarginAccount storage account = marginAccounts[trader];

        if (account.borrowed[tokenTo] > 0) {
            extinguishableDebt = min(outAmount, account.borrowed[tokenTo]);
            extinguishDebt(account, tokenTo, extinguishableDebt);
            totalShort[tokenTo] -= extinguishableDebt;
        }

        uint256 sellAmount = inAmount;
        uint256 fromHoldings = account.holdings[tokenFrom];
        if (inAmount > fromHoldings) {
            sellAmount = fromHoldings;
            /// won't overflow
            borrowAmount = inAmount - sellAmount;
        }

        if (inAmount > borrowAmount) {
            totalLong[tokenFrom] -= inAmount - borrowAmount;
        }
        if (outAmount > extinguishableDebt) {
            totalLong[tokenTo] += outAmount - extinguishableDebt;
        }
        require(
            tokenCaps[tokenTo] >= totalLong[tokenTo],
            "Exceeds global token cap"
        );

        adjustAmounts(
            account,
            tokenFrom,
            tokenTo,
            sellAmount,
            outAmount - extinguishableDebt
        );

        if (borrowAmount > 0) {
            totalShort[tokenFrom] += borrowAmount;
            require(
                tokenCaps[tokenFrom] >= totalShort[tokenFrom],
                "Exceeds global token cap"
            );
            borrow(account, tokenFrom, borrowAmount);
        }
    }

    /// @dev can get called by router to register the dissolution of an account
    function registerLiquidation(address trader) external override {
        require(isMarginTrader(msg.sender), "Calling contr. not authorized");
        CrossMarginAccount storage account = marginAccounts[trader];
        require(loanInPeg(account) == 0, "Can't liquidate: borrowing");

        deleteAccount(account);
    }

    /// @dev currently holding in this token
    function viewBalanceInToken(address trader, address token)
        external
        view
        returns (uint256)
    {
        CrossMarginAccount storage account = marginAccounts[trader];
        return account.holdings[token];
    }

    /// @dev view function to display account held assets state
    function getHoldingAmounts(address trader)
        external
        view
        override
        returns (
            address[] memory holdingTokens,
            uint256[] memory holdingAmounts
        )
    {
        CrossMarginAccount storage account = marginAccounts[trader];
        holdingTokens = account.holdingTokens;

        holdingAmounts = new uint256[](account.holdingTokens.length);
        for (uint256 idx = 0; holdingTokens.length > idx; idx++) {
            address tokenAddress = holdingTokens[idx];
            holdingAmounts[idx] = account.holdings[tokenAddress];
        }
    }

    /// @dev view function to display account borrowing state
    function getBorrowAmounts(address trader)
        external
        view
        override
        returns (address[] memory borrowTokens, uint256[] memory borrowAmounts)
    {
        CrossMarginAccount storage account = marginAccounts[trader];
        borrowTokens = account.borrowTokens;

        borrowAmounts = new uint256[](account.borrowTokens.length);
        for (uint256 idx = 0; borrowTokens.length > idx; idx++) {
            address tokenAddress = borrowTokens[idx];
            borrowAmounts[idx] = Lending(lending()).viewWithBorrowInterest(
                account.borrowed[tokenAddress],
                tokenAddress,
                account.borrowedYieldQuotientsFP[tokenAddress]
            );
        }
    }

    /// @dev view function to get loan amount in peg
    function viewLoanInPeg(address trader)
        external
        view
        returns (uint256 amount)
    {
        CrossMarginAccount storage account = marginAccounts[trader];
        return
            viewTokensInPegWithYield(
                account.borrowTokens,
                account.borrowed,
                account.borrowedYieldQuotientsFP
            );
    }

    /// @dev total of assets of account, expressed in reference currency
    function viewHoldingsInPeg(address trader) external view returns (uint256) {
        CrossMarginAccount storage account = marginAccounts[trader];
        return viewTokensInPeg(account.holdingTokens, account.holdings);
    }

    /// @dev can this trader be liquidated?
    function canBeLiquidated(address trader) external view returns (bool) {
        CrossMarginAccount storage account = marginAccounts[trader];
        uint256 loan =
            viewTokensInPegWithYield(
                account.borrowTokens,
                account.borrowed,
                account.borrowedYieldQuotientsFP
            );

        uint256 holdings =
            viewTokensInPeg(account.holdingTokens, account.holdings);

        return 100 * holdings >= liquidationThresholdPercent * loan;
    }
}
