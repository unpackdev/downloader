// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeCast.sol";

import "./SupervisorInterface.sol";
import "./MTokenInterfaces.sol";
import "./InterestRateModel.sol";
import "./ErrorCodes.sol";

/**
 * @title Minterest MToken Contract
 * @notice Abstract base for MTokens
 * @author Minterest
 */
contract MToken is MTokenInterface, MTokenStorage {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /**
     * @notice Initialize the money market
     * @param supervisor_ The address of the Supervisor
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ EIP-20 name of this token
     * @param symbol_ EIP-20 symbol of this token
     * @param decimals_ EIP-20 decimal precision of this token
     * @param underlying_ The address of the underlying asset
     */
    function initialize(
        address admin_,
        SupervisorInterface supervisor_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        IERC20 underlying_
    ) external {
        //slither-disable-next-line incorrect-equality
        require(accrualBlockNumber == 0 && borrowIndex == 0, ErrorCodes.SECOND_INITIALIZATION);

        // Set initial exchange rate
        require(initialExchangeRateMantissa_ > 0, ErrorCodes.ZERO_EXCHANGE_RATE);
        initialExchangeRateMantissa = initialExchangeRateMantissa_;

        // Set the supervisor
        _setSupervisor(supervisor_);

        // Initialize block number and borrow index (block number mocks depend on supervisor being set)
        accrualBlockNumber = getBlockNumber();
        borrowIndex = EXP_SCALE; // = 1e18

        // Set the interest rate model (depends on block number / borrow index)
        setInterestRateModelFresh(interestRateModel_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TIMELOCK, admin_);

        underlying = underlying_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        maxFlashLoanShare = 0.1e18; // 10%
        flashLoanFeeShare = 0.0005e18; // 0.05%
    }

    function totalSupply() external view override returns (uint256) {
        return totalTokenSupply;
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     */
    //slither-disable-next-line reentrancy-benign
    function transferTokens(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal {
        /* Do not allow self-transfers */
        require(src != dst, ErrorCodes.INVALID_DESTINATION);

        /* Fail if transfer not allowed */
        //slither-disable-next-line reentrancy-events
        supervisor.beforeTransfer(address(this), src, dst, tokens);

        /* Get the allowance, infinite for the account owner */
        uint256 startingAllowance = 0;
        if (spender == src) {
            startingAllowance = type(uint256).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS

        accountTokens[src] -= tokens;
        accountTokens[dst] += tokens;

        if (startingAllowance != type(uint256).max) {
            transferAllowances[src][spender] = startingAllowance - tokens;
        }

        emit Transfer(src, dst, tokens);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external override nonReentrant returns (bool) {
        transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external override nonReentrant returns (bool) {
        transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view override returns (uint256) {
        return accountTokens[owner];
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external override returns (uint256) {
        return (accountTokens[owner] * exchangeRateCurrent()) / EXP_SCALE;
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by supervisor to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 mTokenBalance = accountTokens[account];
        uint256 borrowBalance = borrowBalanceStoredInternal(account);
        uint256 exchangeRateMantissa = exchangeRateStoredInternal();
        return (mTokenBalance, borrowBalance, exchangeRateMantissa);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    //slither-disable-next-line dead-code
    function getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this mToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view override returns (uint256) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalProtocolInterest);
    }

    /**
     * @notice Returns the current per-block supply interest rate for this mToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view override returns (uint256) {
        return
            interestRateModel.getSupplyRate(
                getCashPrior(),
                totalBorrows,
                totalProtocolInterest,
                protocolInterestFactorMantissa
            );
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external override nonReentrant returns (uint256) {
        accrueInterest();
        return totalBorrows;
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's
     *         borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external override nonReentrant returns (uint256) {
        accrueInterest();
        return borrowBalanceStored(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public view override returns (uint256) {
        return borrowBalanceStoredInternal(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return the calculated balance
     */
    function borrowBalanceStoredInternal(address account) internal view returns (uint256) {
        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) return 0;

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        return (borrowSnapshot.principal * borrowIndex) / borrowSnapshot.interestIndex;
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public override nonReentrant returns (uint256) {
        accrueInterest();
        return exchangeRateStored();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view override returns (uint256) {
        return exchangeRateStoredInternal();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return calculated exchange rate scaled by 1e18
     */
    function exchangeRateStoredInternal() internal view virtual returns (uint256) {
        if (totalTokenSupply <= 0) {
            /*
             * If there are no tokens lent:
             *  exchangeRate = initialExchangeRate
             */
            return initialExchangeRateMantissa;
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalProtocolInterest) / totalTokenSupply
             */
            return ((getCashPrior() + totalBorrows - totalProtocolInterest) * EXP_SCALE) / totalTokenSupply;
        }
    }

    /**
     * @notice Get cash balance of this mToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view override returns (uint256) {
        return getCashPrior();
    }

    /**
     * @notice Applies accrued interest to total borrows and protocol interest
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() public virtual override {
        /* Remember the initial block number */
        uint256 currentBlockNumber = getBlockNumber();
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) return;

        /* Read the previous values out of storage */
        uint256 cashPrior = getCashPrior();
        uint256 borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint256 borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, totalBorrows, totalProtocolInterest);
        require(borrowRateMantissa <= borrowRateMaxMantissa, ErrorCodes.BORROW_RATE_TOO_HIGH);

        /* Calculate the number of blocks elapsed since the last accrual */
        uint256 blockDelta = currentBlockNumber - accrualBlockNumberPrior;

        /*
         * Calculate the interest accumulated into borrows and protocol interest and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrows += interestAccumulated
         *  totalProtocolInterest += interestAccumulated * protocolInterestFactor
         *  borrowIndex = simpleInterestFactor * borrowIndex + borrowIndex
         */
        uint256 simpleInterestFactor = borrowRateMantissa * blockDelta;
        uint256 interestAccumulated = (totalBorrows * simpleInterestFactor) / EXP_SCALE;
        totalBorrows += interestAccumulated;
        totalProtocolInterest += (interestAccumulated * protocolInterestFactorMantissa) / EXP_SCALE;
        borrowIndex = borrowIndexPrior + (borrowIndexPrior * simpleInterestFactor) / EXP_SCALE;

        accrualBlockNumber = currentBlockNumber;

        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndex, totalBorrows, totalProtocolInterest);
    }

    /**
     * @notice Sender supplies assets into the market and receives mTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param lendAmount The amount of the underlying asset to supply
     */
    function lend(uint256 lendAmount) external override {
        accrueInterest();
        lendFresh(msg.sender, lendAmount);
    }

    /**
     * @notice Account supplies assets into the market and receives mTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param lender The address of the account which is supplying the assets
     * @param lendAmount The amount of the underlying asset to supply
     * @return actualLendAmount actual lend amount
     */
    function lendFresh(address lender, uint256 lendAmount) internal nonReentrant returns (uint256 actualLendAmount) {
        uint256 wrapBalance = accountTokens[lender];
        supervisor.beforeLend(address(this), lender, wrapBalance);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        /*
         *  We call `doTransferIn` for the lender and the lendAmount.
         *  Note: The mToken must handle variations between ERC-20 underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the mToken holds an additional `actualLendAmount`
         *  of cash.
         */
        // slither-disable-next-line reentrancy-eth
        actualLendAmount = doTransferIn(lender, lendAmount);

        /*
         * We get the current exchange rate and calculate the number of mTokens to be lent:
         *  lendTokens = actualLendAmount / exchangeRate
         */
        uint256 lendTokens = (actualLendAmount * EXP_SCALE) / exchangeRateMantissa;

        /*
         * We calculate the new total supply of mTokens and lender token balance, checking for overflow:
         *  totalTokenSupply = totalTokenSupply + lendTokens
         *  accountTokens = accountTokens[lender] + lendTokens
         */
        uint256 newTotalTokenSupply = totalTokenSupply + lendTokens;
        totalTokenSupply = newTotalTokenSupply;
        accountTokens[lender] = wrapBalance + lendTokens;

        emit Lend(lender, actualLendAmount, lendTokens, newTotalTokenSupply);
        emit Transfer(address(this), lender, lendTokens);
    }

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of mTokens to redeem into underlying
     */
    function redeem(uint256 redeemTokens) external override {
        accrueInterest();
        redeemFresh(msg.sender, redeemTokens, 0);
    }

    /**
     * @notice Sender redeems mTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming mTokens
     */
    function redeemUnderlying(uint256 redeemAmount) external override {
        accrueInterest();
        redeemFresh(msg.sender, 0, redeemAmount);
    }

    /**
     * @notice Account redeems mTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokens The number of mTokens to redeem into underlying
     *                       (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmount The number of underlying tokens to receive from redeeming mTokens
     *                       (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     */
    //slither-disable-next-line reentrancy-no-eth
    function redeemFresh(
        address redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) internal nonReentrant {
        require(redeemTokens == 0 || redeemAmount == 0, ErrorCodes.REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO);

        /* exchangeRate = invoke Exchange Rate Stored() */
        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        if (redeemTokens > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokens
             *  redeemAmount = redeemTokens * exchangeRateCurrent
             */
            redeemAmount = (redeemTokens * exchangeRateMantissa) / EXP_SCALE;
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmount / exchangeRate
             *  redeemAmount = redeemAmount
             */
            redeemTokens = (redeemAmount * EXP_SCALE) / exchangeRateMantissa;
        }

        /* Fail if redeem not allowed */
        //slither-disable-next-line reentrancy-benign
        supervisor.beforeRedeem(address(this), redeemer, redeemTokens);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);
        require(accountTokens[redeemer] >= redeemTokens, ErrorCodes.REDEEM_TOO_MUCH);
        require(totalTokenSupply >= redeemTokens, ErrorCodes.INVALID_REDEEM);

        /*
         * We calculate the new total supply and redeemer balance, checking for underflow:
         *  accountTokensNew = accountTokens[redeemer] - redeemTokens
         *  totalSupplyNew = totalTokenSupply - redeemTokens
         */
        uint256 accountTokensNew = accountTokens[redeemer] - redeemTokens;
        uint256 totalSupplyNew = totalTokenSupply - redeemTokens;

        /* Fail gracefully if protocol has insufficient cash */
        require(getCashPrior() >= redeemAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);

        totalTokenSupply = totalSupplyNew;
        accountTokens[redeemer] = accountTokensNew;

        //slither-disable-next-line reentrancy-events
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens, totalSupplyNew);

        doTransferOut(redeemer, redeemAmount);

        /* We call the defense hook */
        supervisor.redeemVerify(redeemAmount, redeemTokens);
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */

    //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
    function borrow(uint256 borrowAmount) external override nonReentrant {
        accrueInterest();

        address borrower = msg.sender;

        /* Fail if borrow not allowed */
        //slither-disable-next-line reentrancy-benign
        supervisor.beforeBorrow(address(this), borrower, borrowAmount);

        /* Fail gracefully if protocol has insufficient underlying cash */
        require(getCashPrior() >= borrowAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        uint256 accountBorrowsNew = borrowBalanceStoredInternal(borrower) + borrowAmount;
        uint256 totalBorrowsNew = totalBorrows + borrowAmount;

        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        //slither-disable-next-line reentrancy-events
        emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);

        doTransferOut(borrower, borrowAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     */
    function repayBorrow(uint256 repayAmount) external override {
        accrueInterest();
        repayBorrowFresh(msg.sender, msg.sender, repayAmount);
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external override {
        accrueInterest();
        repayBorrowFresh(msg.sender, borrower, repayAmount);
    }

    /**
     * @notice Borrows are repaid by another account (possibly the borrower).
     * @param payer the account paying off the borrow
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of underlying tokens being returned
     * @return actualRepayAmount the actual repayment amount
     */
    function repayBorrowFresh(
        address payer,
        address borrower,
        uint256 repayAmount
    ) internal nonReentrant returns (uint256 actualRepayAmount) {
        /* Fail if repayBorrow not allowed */
        supervisor.beforeRepayBorrow(address(this), borrower);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        /* We fetch the amount the borrower owes, with accumulated interest */
        uint256 borrowBalance = borrowBalanceStoredInternal(borrower);

        if (repayAmount == type(uint256).max) {
            repayAmount = borrowBalance;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The mToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the mToken holds an additional repayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        // slither-disable-next-line reentrancy-eth
        actualRepayAmount = doTransferIn(payer, repayAmount);

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        uint256 accountBorrowsNew = borrowBalance - actualRepayAmount;
        uint256 totalBorrowsNew = totalBorrows - actualRepayAmount;

        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        emit RepayBorrow(payer, borrower, actualRepayAmount, accountBorrowsNew, totalBorrowsNew);
    }

    /**
     * @notice Liquidator repays a borrow belonging to borrower
     * @param borrower_ the account with the debt being payed off
     * @param repayAmount_ the amount of underlying tokens being returned
     */
    function autoLiquidationRepayBorrow(address borrower_, uint256 repayAmount_) external override nonReentrant {
        // Fail if repayBorrow not allowed
        //slither-disable-next-line reentrancy-benign
        supervisor.beforeAutoLiquidationRepay(msg.sender, borrower_, address(this), borrowIndex.toUint224());

        // Verify market's block number equals current block number
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);
        require(totalProtocolInterest >= repayAmount_, ErrorCodes.INSUFFICIENT_TOTAL_PROTOCOL_INTEREST);

        // We fetch the amount the borrower owes, with accumulated interest
        uint256 borrowBalance = borrowBalanceStoredInternal(borrower_);

        accountBorrows[borrower_].principal = borrowBalance - repayAmount_;
        accountBorrows[borrower_].interestIndex = borrowIndex;
        totalBorrows -= repayAmount_;
        totalProtocolInterest -= repayAmount_;

        //slither-disable-next-line reentrancy-events
        emit AutoLiquidationRepayBorrow(
            borrower_,
            repayAmount_,
            accountBorrows[borrower_].principal,
            totalBorrows,
            totalProtocolInterest
        );
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract.
     *         Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     */
    function sweepToken(IERC20 token, address receiver_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != underlying, ErrorCodes.INVALID_TOKEN);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(receiver_, balance);
    }

    /**
     * @notice Burns collateral tokens at the borrower's address, transfer underlying assets
     to the DeadDrop or Liquidator address.
     * @dev Called only during an auto liquidation process, msg.sender must be the Liquidation contract.
     * @param borrower_ The account having collateral seized
     * @param seizeUnderlyingAmount_ The number of underlying assets to seize. The caller must ensure
     that the parameter is greater than zero.
     * @param isLoanInsignificant_ Marker for insignificant loan whose collateral must be credited to the
     protocolInterest
     * @param receiver_ Address that receives accounts collateral
     */
    //slither-disable-next-line reentrancy-benign
    function autoLiquidationSeize(
        address borrower_,
        uint256 seizeUnderlyingAmount_,
        bool isLoanInsignificant_,
        address receiver_
    ) external nonReentrant {
        //slither-disable-next-line reentrancy-events
        supervisor.beforeAutoLiquidationSeize(address(this), msg.sender, borrower_);

        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        uint256 borrowerSeizeTokens;

        // Infinity means all account's collateral has to be burn.
        if (seizeUnderlyingAmount_ == type(uint256).max) {
            borrowerSeizeTokens = accountTokens[borrower_];
            seizeUnderlyingAmount_ = (borrowerSeizeTokens * exchangeRateMantissa) / EXP_SCALE;
        } else {
            borrowerSeizeTokens = (seizeUnderlyingAmount_ * EXP_SCALE) / exchangeRateMantissa;
        }

        uint256 borrowerTokensNew = accountTokens[borrower_] - borrowerSeizeTokens;
        uint256 totalSupplyNew = totalTokenSupply - borrowerSeizeTokens;

        /////////////////////////
        // EFFECTS & INTERACTIONS

        accountTokens[borrower_] = borrowerTokensNew;
        totalTokenSupply = totalSupplyNew;

        if (isLoanInsignificant_) {
            totalProtocolInterest = totalProtocolInterest + seizeUnderlyingAmount_;
            emit ProtocolInterestAdded(msg.sender, seizeUnderlyingAmount_, totalProtocolInterest);
        } else {
            doTransferOut(receiver_, seizeUnderlyingAmount_);
        }

        emit Seize(
            borrower_,
            receiver_,
            borrowerSeizeTokens,
            borrowerTokensNew,
            totalSupplyNew,
            seizeUnderlyingAmount_
        );
    }

    /*** Flash loans ***/

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view override returns (uint256) {
        return token == address(underlying) ? _maxFlashLoan() : 0;
    }

    function _maxFlashLoan() internal view returns (uint256) {
        return (getCashPrior() * maxFlashLoanShare) / EXP_SCALE;
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view override returns (uint256) {
        require(token == address(underlying), ErrorCodes.FL_TOKEN_IS_NOT_UNDERLYING);
        return _flashFee(amount);
    }

    function _flashFee(uint256 amount) internal view returns (uint256) {
        return (amount * flashLoanFeeShare) / EXP_SCALE;
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    // slither-disable-next-line reentrancy-benign
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override nonReentrant returns (bool) {
        require(token == address(underlying), ErrorCodes.FL_TOKEN_IS_NOT_UNDERLYING);
        require(amount <= _maxFlashLoan(), ErrorCodes.FL_AMOUNT_IS_TOO_LARGE);

        accrueInterest();

        // Make supervisor checks
        uint256 fee = _flashFee(amount);
        supervisor.beforeFlashLoan(address(this), address(receiver), amount, fee);

        // Transfer lend amount to receiver and call its callback
        underlying.safeTransfer(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == FLASH_LOAN_SUCCESS,
            ErrorCodes.FL_CALLBACK_FAILED
        );

        // Transfer amount + fee back and check that everything was returned by token
        uint256 actualPullAmount = doTransferIn(address(receiver), amount + fee);
        require(actualPullAmount >= amount + fee, ErrorCodes.FL_PULL_AMOUNT_IS_TOO_LOW);

        // Fee is the protocol interest so we increase it
        totalProtocolInterest += fee;

        emit FlashLoanExecuted(address(receiver), amount, fee);

        return true;
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new supervisor for the market
     * @dev Admin function to set a new supervisor
     */
    function setSupervisor(SupervisorInterface newSupervisor) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setSupervisor(newSupervisor);
    }

    function _setSupervisor(SupervisorInterface newSupervisor) internal {
        require(
            newSupervisor.supportsInterface(type(SupervisorInterface).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );

        SupervisorInterface oldSupervisor = supervisor;
        supervisor = newSupervisor;
        emit NewSupervisor(oldSupervisor, newSupervisor);
    }

    /**
     * @notice accrues interest and sets a new protocol interest factor for the protocol
     * @dev Admin function to accrue interest and set a new protocol interest factor
     */
    function setProtocolInterestFactor(uint256 newProtocolInterestFactorMantissa)
        external
        override
        onlyRole(TIMELOCK)
        nonReentrant
    {
        // Check newProtocolInterestFactor ≤ maxProtocolInterestFactor
        require(
            newProtocolInterestFactorMantissa <= protocolInterestFactorMaxMantissa,
            ErrorCodes.INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA
        );

        accrueInterest();

        uint256 oldProtocolInterestFactorMantissa = protocolInterestFactorMantissa;
        protocolInterestFactorMantissa = newProtocolInterestFactorMantissa;

        emit NewProtocolInterestFactor(oldProtocolInterestFactorMantissa, newProtocolInterestFactorMantissa);
    }

    /**
     * @notice Accrues interest and increase protocol interest by transferring from msg.sender
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterest(uint256 addAmount_) external override nonReentrant {
        accrueInterest();
        addProtocolInterestInternal(msg.sender, addAmount_);
    }

    /**
     * @notice Can only be called by liquidation contract. Increase protocol interest by transferring from payer.
     * @dev Calling code should make sure that accrueInterest() was called before.
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestBehalf(address payer_, uint256 addAmount_) external override nonReentrant {
        supervisor.isLiquidator(msg.sender);
        addProtocolInterestInternal(payer_, addAmount_);
    }

    /**
     * @notice Accrues interest and increase protocol interest by transferring from payer_
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestInternal(address payer_, uint256 addAmount_) internal {
        // Verify market's block number equals current block number
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        /*
         * We call doTransferIn for the caller and the addAmount
         *  Note: The mToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the mToken holds an additional addAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *  it returns the amount actually transferred, in case of a fee.
         */
        // slither-disable-next-line reentrancy-eth
        uint256 actualAddAmount = doTransferIn(payer_, addAmount_);
        uint256 totalProtocolInterestNew = totalProtocolInterest + actualAddAmount;

        // Store protocolInterest[n+1] = protocolInterest[n] + actualAddAmount
        totalProtocolInterest = totalProtocolInterestNew;

        emit ProtocolInterestAdded(payer_, actualAddAmount, totalProtocolInterestNew);
    }

    /**
     * @notice Accrues interest and reduces protocol interest by transferring to admin
     * @param reduceAmount Amount of reduction to protocol interest
     */
    function reduceProtocolInterest(uint256 reduceAmount, address receiver_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        accrueInterest();

        // Check if protocol has insufficient underlying cash
        require(getCashPrior() >= reduceAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);
        require(totalProtocolInterest >= reduceAmount, ErrorCodes.INVALID_REDUCE_AMOUNT);

        /////////////////////////
        // EFFECTS & INTERACTIONS

        uint256 totalProtocolInterestNew = totalProtocolInterest - reduceAmount;
        totalProtocolInterest = totalProtocolInterestNew;

        // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        doTransferOut(receiver_, reduceAmount);

        emit ProtocolInterestReduced(receiver_, reduceAmount, totalProtocolInterestNew);
    }

    /**
     * @notice accrues interest and updates the interest rate model using setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     */
    function setInterestRateModel(InterestRateModel newInterestRateModel)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        accrueInterest();
        setInterestRateModelFresh(newInterestRateModel);
    }

    /**
     * @notice updates the interest rate model (*requires fresh interest accrual)
     * @dev Admin function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     */
    function setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal {
        require(
            newInterestRateModel.supportsInterface(type(InterestRateModel).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        InterestRateModel oldInterestRateModel = interestRateModel;
        interestRateModel = newInterestRateModel;

        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
    }

    /**
     * @notice Updates share of markets cash that can be used as maximum amount of flash loan.
     * @param newMax New max amount share
     */
    function setFlashLoanMaxShare(uint256 newMax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newMax <= EXP_SCALE, ErrorCodes.FL_PARAM_IS_TOO_LARGE);
        emit NewFlashLoanMaxShare(maxFlashLoanShare, newMax);
        maxFlashLoanShare = newMax;
    }

    /**
     * @notice Updates fee of flash loan.
     * @param newFee New fee share of flash loan
     */
    function setFlashLoanFeeShare(uint256 newFee) external onlyRole(TIMELOCK) {
        require(newFee <= EXP_SCALE, ErrorCodes.FL_PARAM_IS_TOO_LARGE);
        emit NewFlashLoanFee(flashLoanFeeShare, newFee);
        flashLoanFeeShare = newFee;
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view virtual returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here:
     *            https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint256 amount) internal virtual returns (uint256) {
        uint256 balanceBefore = underlying.balanceOf(address(this));
        underlying.safeTransferFrom(from, address(this), amount);

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = underlying.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, ErrorCodes.TOKEN_TRANSFER_IN_UNDERFLOW);
        return balanceAfter - balanceBefore;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer`
     *      and returns an explanatory error code rather than reverting. If caller has not
     *      called checked protocol's balance, this may revert due to insufficient cash held
     *      in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here:
     *            https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address to, uint256 amount) internal virtual {
        underlying.safeTransfer(to, amount);
    }

    /**
     * @notice Admin call to delegate the votes of the MNT-like underlying
     * @param mntLikeDelegatee The address to delegate votes to
     * @dev MTokens whose underlying are not MntLike should revert here
     */
    function delegateMntLikeTo(address mntLikeDelegatee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MntLike(address(underlying)).delegate(mntLikeDelegatee);
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, IERC165) returns (bool) {
        return
            interfaceId == type(MTokenInterface).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC3156FlashLender).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
