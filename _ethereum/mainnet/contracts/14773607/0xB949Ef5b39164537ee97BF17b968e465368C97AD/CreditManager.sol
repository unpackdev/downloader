// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

// LIBRARIES
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./ACLTrait.sol";

// INTERFACES
import "./IAccountFactory.sol";
import "./ICreditAccount.sol";
import "./IPoolService.sol";
import "./IWETHGateway.sol";
import "./ICreditManagerV2.sol";
import "./IAddressProvider.sol";
import "./IPriceOracle.sol";

// CONSTANTS
import "./PercentageMath.sol";
import "./Constants.sol";

// EXCEPTIONS
import "./IErrors.sol";

import "./console.sol";

/// @title Credit Manager
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
contract CreditManager is ICreditManagerV2, ACLTrait, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    // Mapping between borrowers'/farmers' address and credit account
    mapping(address => address) public override creditAccounts;

    // Account manager - provides credit accounts to pool
    IAccountFactory internal immutable _accountFactory;

    // Underlying token address
    address public immutable override underlying;

    // [DEPRICIATED]: Address of connected pool, user pool instead!
    address public immutable override poolService;

    // [DEPRICIATED]: Address of connected pool, user pool instead!
    address public immutable override pool;

    // Address of WETH token
    address public immutable override wethAddress;

    // Address of WETH Gateway
    address public immutable wethGateway;

    // Minimal borrowed amount per credit account
    uint256 public override minBorrowedAmount;

    // Maximum aborrowed amount per credit account
    uint256 public override maxBorrowedAmount;

    // Interest fee protocol charges: fee = interest accrues * feeInterest
    uint256 public override feeInterest;

    // Liquidation fee protocol charges: fee = totalValue * feeLiquidation
    uint256 public override feeLiquidation;

    // Miltiplier to get amount which liquidator should pay: amount = totalValue * liquidationDiscount
    uint256 public override liquidationDiscount;

    // Address of creditFacade
    address public override creditFacade;

    // Adress of creditConfigurator
    address public creditConfigurator;

    // Allowed tokens array
    address[] public override allowedTokens;

    // Allowed contracts list
    mapping(address => uint256) public override liquidationThresholds;

    // map token address to its mask
    mapping(address => uint256) public override tokenMasksMap;

    // Mask for forbidden tokens
    uint256 public override forbiddenTokenMask;

    // credit account token enables mask. each bit (in order as tokens stored in allowedTokens array) set 1 if token was enable
    mapping(address => uint256) public override enabledTokensMap;

    // keeps last block we use fast check. Fast check is not allowed to use more than one time in block
    mapping(address => uint256) public fastCheckCounter;

    // Allowed adapters list
    mapping(address => address) public override adapterToContract;

    // Price oracle - uses in evaluation credit account
    IPriceOracleV2 public override priceOracle;

    // Minimum chi threshold allowed for fast check
    uint256 public chiThreshold;

    // Maxmimum allowed fast check operations between full health factor checks
    uint256 public hfCheckInterval;

    // Contract version
    uint256 public constant override version = 2;

    //
    // MODIFIERS
    //

    /// Checks that sender is adapter
    modifier adaptersOrFacadeOnly() {
        if (
            adapterToContract[msg.sender] == address(0) &&
            msg.sender != creditFacade
        ) revert AdaptersOrFacadeOnlyException(); // T:[CF-20]
        _;
    }

    /// @dev Restricts actions for users with opened credit accounts only
    modifier creditFacadeOnly() {
        if (msg.sender != creditFacade) revert NotCreditFacadeException();
        _;
    }

    /// @dev Restricts actions for users with opened credit accounts only
    modifier creditConfiguratorOnly() {
        if (msg.sender != creditConfigurator)
            revert NotCreditConfiguratorException();
        _;
    }

    /// @dev Constructor
    /// @param _poolService Address of pool service
    constructor(address _poolService)
        ACLTrait(address(IPoolService(_poolService).addressProvider()))
    {
        if (_poolService == address(0)) revert ZeroAddressException();

        IAddressProvider addressProvider = IPoolService(_poolService)
        .addressProvider();

        pool = _poolService; // F:[CM-1]
        poolService = _poolService;

        address _underlying = IPoolService(pool).underlyingToken();
        underlying = _underlying; // F:[CM-1]

        _addToken(_underlying); // F:[CM-1]
        tokenMasksMap[_underlying] = 1;

        wethAddress = addressProvider.getWethToken(); // F:[CM-1]
        wethGateway = addressProvider.getWETHGateway(); // F:[CM-1]
        priceOracle = IPriceOracleV2(addressProvider.getPriceOracle()); // F:[CM-1]
        _accountFactory = IAccountFactory(addressProvider.getAccountFactory()); // F:[CM-1]
        creditConfigurator = msg.sender; // TODO: add test
    }

    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///  @dev Opens credit account and provides credit funds.
    /// - Opens credit account (take it from account factory)
    /// - Transfers borrowed leveraged amount from pool calling lendCreditAccount() on connected Pool contract.
    /// Function reverts if user has already opened position
    ///
    /// @param borrowedAmount Margin loan amount which should be transffered to credit account
    /// @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
    ///  or a different address if the beneficiary is a different wallet
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (address)
    {
        // Checks that amount is in limits
        if (
            borrowedAmount < minBorrowedAmount ||
            borrowedAmount > maxBorrowedAmount
        ) revert BorrowAmountOutOfLimitsException(); // F:[CM-7]

        // Get Reusable creditAccount from account factory
        address creditAccount = _accountFactory.takeCreditAccount(
            borrowedAmount,
            IPoolService(pool).calcLinearCumulative_RAY()
        ); // F:[CM-9]

        // Transfer pool tokens to new credit account
        IPoolService(pool).lendCreditAccount(borrowedAmount, creditAccount); // F:[CM-9]

        // Checks that credit account doesn't overwrite existing one and connects it with borrower
        _safeCreditAccountSet(onBehalfOf, creditAccount); // F:[CM-8,9]

        // Initializes enabled tokens for credit account.
        // Enabled tokens is a bit mask which holds information which tokens were used by user
        enabledTokensMap[creditAccount] = 1; // F:[CM-9]
        fastCheckCounter[creditAccount] = 1; // F:[CM-9]

        return creditAccount;
    }

    ///  @dev Closes credit account
    /// - Computes amountToPool and remaningFunds (for liquidation case only)
    /// - Checks underlying token balance:
    ///    + if it > than funds need to be paid to pool, the debt is paid by funds from creditAccount
    ///    + if there is no enough funds in credit Account, it withdraws all funds from credit account, and then
    ///      transfers the diff from payer address
    /// - Then, if sendAllAssets is true, it transfers all non-zero balances from credit account to address "to"
    /// - If convertWETH is true, the function converts WETH into ETH on the fly
    /// - Returns creditAccount to factory back
    ///
    /// @param borrower Borrower address
    /// @param isLiquidated True if it's called for liquidation
    /// @param totalValue Portfolio value for liqution, 0 for ordinary closure
    /// @param payer Address which would be charged if credit account has not enough funds to cover amountToPool
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH If true converts WETH to ETH

    function closeCreditAccount(
        address borrower,
        bool isLiquidated,
        uint256 totalValue, // 0 if not liquidated
        address payer,
        address to,
        uint256 skipTokenMask,
        bool convertWETH
    )
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (uint256 remainingFunds)
    {
        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]

        // Makes all computations needed to close credit account
        uint256 amountToPool;
        uint256 borrowedAmount;

        {
            uint256 profit;
            uint256 loss;
            uint256 borrowedAmountWithInterest;
            (
                borrowedAmount,
                borrowedAmountWithInterest
            ) = calcCreditAccountAccruedInterest(creditAccount); // F:[CM-11, 12, 13, 14, 15]

            (amountToPool, remainingFunds, profit, loss) = calcClosePayments(
                totalValue,
                isLiquidated,
                borrowedAmount,
                borrowedAmountWithInterest
            ); // F:[CM-11, 12, 13, 14, 15]

            uint256 underlyingBalance = IERC20(underlying).balanceOf(
                creditAccount
            );

            // Transfers surplus in funds from credit account to "to" addrss,
            // it it has more than needed to cover all
            if (underlyingBalance > amountToPool + remainingFunds + 1) {
                unchecked {
                    _safeTokenTransfer(
                        creditAccount,
                        underlying,
                        to,
                        underlyingBalance - amountToPool - remainingFunds - 1,
                        convertWETH
                    ); // F:[CM-11, 13, 16]
                }
            } else {
                // Transfers money from payer account to get enough funds on credit account to
                // cover necessary payments
                unchecked {
                    IERC20(underlying).safeTransferFrom(
                        payer, // borrower or liquidator
                        creditAccount,
                        amountToPool + remainingFunds - underlyingBalance + 1
                    ); // F:[CM-12]
                }
            }

            // Transfers amountToPool to pool
            _safeTokenTransfer(
                creditAccount,
                underlying,
                pool,
                amountToPool,
                false
            ); // F:[CM-11, 12, 13, 14]

            // Updates pool with tokens would be sent soon
            IPoolService(pool).repayCreditAccount(borrowedAmount, profit, loss); // F:[CM-11, 12, 13, 14]
        }

        // transfer remaining funds to borrower [Liquidation case only]
        if (remainingFunds > 1) {
            _safeTokenTransfer(
                creditAccount,
                underlying,
                borrower,
                remainingFunds,
                false
            ); // F:[CM-14, 16]
        }

        enabledTokensMap[creditAccount] &= ~skipTokenMask;
        _transferAssetsTo(creditAccount, to, convertWETH); // F:[CM-15]

        // Return creditAccount
        _accountFactory.returnCreditAccount(creditAccount); // F:[CM-10]

        // Release memory
        delete creditAccounts[borrower]; // F:[CM-10]
    }

    /// @dev Manages debt size for borrower:
    ///
    /// - Increase case:
    ///   + Increase debt by tranferring funds from the pool to the credit account
    ///   + Updates cunulativeIndex to accrue interest rate.
    ///
    /// - Decresase debt:
    ///   + Repay particall debt + all interest accrued at the moment + all fees accrued at the moment
    ///   + Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param borrower Borrowed address
    /// @param amount Amount to increase borrowed amount
    /// @param increase True fto increase debt, false to decrease
    /// @return newBorrowedAmount Updated amount
    function manageDebt(
        address borrower,
        uint256 amount,
        bool increase
    )
        external
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (uint256 newBorrowedAmount)
    {
        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]

        (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen,
            uint256 cumulativeIndexNow
        ) = _getCreditAccountParameters(creditAccount);

        // Computes new amount
        newBorrowedAmount = increase
            ? borrowedAmount + amount // F:[CM-17, 18]
            : borrowedAmount - amount; // F:[CM-17]

        if (
            newBorrowedAmount < minBorrowedAmount ||
            newBorrowedAmount > maxBorrowedAmount
        ) revert BorrowAmountOutOfLimitsException(); // F:[CM-17]

        uint256 newCumulativeIndex;
        if (increase) {
            // Computes new cumulative index which accrues previous debt
            newCumulativeIndex =
                (cumulativeIndexNow *
                    cumulativeIndexAtOpen *
                    newBorrowedAmount) /
                (cumulativeIndexNow *
                    borrowedAmount +
                    amount *
                    cumulativeIndexAtOpen); // F:[CM-18]

            // Lends more money from the pool
            IPoolService(pool).lendCreditAccount(amount, creditAccount);
        } else {
            // Computes interest rate accrued at the moment
            uint256 interestAccrued = (borrowedAmount * cumulativeIndexNow) /
                cumulativeIndexAtOpen -
                borrowedAmount; // F:[CM-19]

            // Computes profit which comes from interest rate
            uint256 profit = (interestAccrued * feeInterest) /
                PERCENTAGE_FACTOR; // F:[CM-19]

            // Pays amount back to pool
            ICreditAccount(creditAccount).safeTransfer(
                underlying,
                pool,
                amount + interestAccrued + profit
            ); // F:[CM-19]

            // Calls repayCreditAccount to update pool values
            IPoolService(pool).repayCreditAccount(
                amount + interestAccrued,
                profit,
                0
            ); // F:[CM-19]

            // Gets updated cumulativeIndex, which could be changed after repayCreditAccount
            // to make precise calculation
            newCumulativeIndex = IPoolService(pool).calcLinearCumulative_RAY();
        }
        //
        // Set parameters for new credit account
        ICreditAccount(creditAccount).updateParameters(
            newBorrowedAmount,
            newCumulativeIndex
        ); // F:[CM-18, 19]
    }

    /// @dev Adds collateral to borrower's credit account
    /// @param payer Address of account which will be charged to provide additional collateral
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address onBehalfOf,
        address token,
        uint256 amount
    )
        external
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
    {
        address creditAccount = getCreditAccountOrRevert(onBehalfOf); // F:[CM-6]
        _checkAndEnableToken(creditAccount, token); // F:[CM-20]
        IERC20(token).safeTransferFrom(payer, creditAccount, amount); // F:[CM-20]
    }

    /// @dev Transfers account ownership to another account
    /// @param from Address of previous owner
    /// @param to Address of new owner
    function transferAccountOwnership(address from, address to)
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
    {
        address creditAccount = getCreditAccountOrRevert(from); // F:[CM-6]
        delete creditAccounts[from]; // F:[CM-22]

        _safeCreditAccountSet(to, creditAccount); // F:[CM-21, 22]
    }

    /// @dev Approve tokens for credit account. Restricted for adapters only
    /// @param borrower Address of borrower
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    /// @param amount Allowanc amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    )
        external
        override
        whenNotPaused // F:[CM-5]
        adaptersOrFacadeOnly // F:[CM-3]
        nonReentrant
    {
        if (msg.sender != creditFacade) {
            if (
                adapterToContract[msg.sender] != targetContract ||
                targetContract == address(0)
            ) revert TargetContractNotAllowedExpcetion(); // F:[CM-23]
        }

        // Additional check that token is connected to this CreditManager
        if (tokenMasksMap[token] == 0) revert TokenNotAllowedException(); // F:[CM-20A]

        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]

        try
            ICreditAccount(creditAccount).execute(
                token,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    targetContract,
                    amount
                )
            )
        {} catch {
            ICreditAccount(creditAccount).execute(
                token,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    targetContract,
                    0
                )
            );
            ICreditAccount(creditAccount).execute(
                token,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    targetContract,
                    amount
                )
            );
        }
    }

    /// @dev Executes filtered order on credit account which is connected with particular borrower
    /// NOTE: This function could be called by adapters only
    /// @param borrower Borrower address
    /// @param targetContract Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address targetContract,
        bytes memory data
    )
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        returns (bytes memory)
    {
        // Checks that targetContract is called from allowed adapter

        // TODO: Check moving to external function
        if (
            adapterToContract[msg.sender] != targetContract ||
            targetContract == address(0)
        ) revert TargetContractNotAllowedExpcetion(); // F:[CM-25]

        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]
        emit ExecuteOrder(borrower, targetContract); // F:[CM-26]
        return ICreditAccount(creditAccount).execute(targetContract, data); // F:[CM-26]
    }

    // Checking collateral functions

    /// @dev Enables token in enableTokenMask for provided credit account,
    //  Reverts if token is not allowed (not added of forbidden)
    /// @param creditAccount Address of creditAccount (not borrower!) to check and enable
    /// @param tokenOut Address of token which would be sent to credit account
    function checkAndEnableToken(address creditAccount, address tokenOut)
        external
        override
        adaptersOrFacadeOnly // F:[CM-3]
    {
        _checkAndEnableToken(creditAccount, tokenOut); // F:[CM-27, 28]
    }

    /// @dev Checks financial order and reverts if tokens aren't in list or collateral protection alerts
    /// @param creditAccount Address of credit account
    /// @param tokenIn Address of token In in swap operation
    /// @param tokenOut Address of token Out in swap operation
    /// @param balanceInBefore Balance of tokenIn before operation
    /// @param balanceOutBefore Balance of tokenOut before operation
    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore
    )
        external
        override
        adaptersOrFacadeOnly // F:[CM-3]
    {
        _checkAndEnableToken(creditAccount, tokenOut); // F:[CM-29]

        // CASE:  fastCheckCounter[creditAccount] > hfCheckInterval) - F:[CM-33]
        if (fastCheckCounter[creditAccount] <= hfCheckInterval) {
            // Convert to WETH is more gas efficient and doesn't make difference for ratio

            uint256 balanceInAfter = IERC20(tokenIn).balanceOf(creditAccount); // F:[CM-30,31,32]
            uint256 balanceOutAfter = IERC20(tokenOut).balanceOf(creditAccount); // F:[CM-30,31,32]

            (
                uint256 amountInCollateral,
                uint256 amountOutCollateral
            ) = priceOracle.fastCheck(
                creditAccount,
                balanceInBefore - balanceInAfter,
                tokenIn,
                balanceOutAfter - balanceOutBefore,
                tokenOut
            ); // F:[CM-30,31,32]

            // Disables tokens, which has balance equals 0 (or 1)
            if (balanceInAfter <= 1) _disableToken(creditAccount, tokenIn); // F:[CM-30]

            if (
                (amountOutCollateral * PERCENTAGE_FACTOR) >
                (amountInCollateral * chiThreshold)
            ) {
                unchecked {
                    ++fastCheckCounter[creditAccount]; // F:[CM-31]
                }
                return;
            }
        }

        /// Calls for fullCollateral check if it doesn't pass fastCollaterCheck
        _fullCollateralCheck(creditAccount); // F:[CM-32]
    }

    /// @dev Provide full collateral check
    /// FullCollateralCheck is lazy checking that credit account has enough collateral
    /// for paying back. It stops if counts that total collateral > debt + interest rate
    /// @param creditAccount Address of credit account (not borrower!)
    function fullCollateralCheck(address creditAccount)
        public
        override
        adaptersOrFacadeOnly // F:[CM-3]
    {
        _fullCollateralCheck(creditAccount);
    }

    /// @dev IMPLEMENTATION: Provide full collateral check
    /// FullCollateralCheck is lazy checking that credit account has enough collateral
    /// for paying back. It stops if counts that total collateral > debt + interest rate
    /// @param creditAccount Address of credit account (not borrower!)
    function _fullCollateralCheck(address creditAccount) internal {
        (
            ,
            uint256 borrowedAmountWithInterest
        ) = calcCreditAccountAccruedInterest(creditAccount);

        // borrowAmountPlusInterestRateUSD x 10.000 to be compared with values x LT
        uint256 borrowAmountPlusInterestRateUSD = priceOracle.convertToUSD(
            creditAccount,
            borrowedAmountWithInterest,
            underlying
        ) * PERCENTAGE_FACTOR;

        uint256 total;
        uint256 tokenMask;
        uint256 eTokens = enabledTokensMap[creditAccount];
        uint256 len = allowedTokens.length;

        for (uint256 i = 0; i < len; ) {
            tokenMask = 1 << i;

            // Statement is checked in F:[CM-34]
            if (eTokens & tokenMask > 0) {
                address token = allowedTokens[i];
                uint256 balance = IERC20(token).balanceOf(creditAccount);

                // balance ==0 :
                if (balance > 1) {
                    total +=
                        priceOracle.convertToUSD(
                            creditAccount,
                            balance,
                            token
                        ) *
                        liquidationThresholds[token];
                } else {
                    _disableToken(creditAccount, token); // F:[CM-35]
                }

                if (total >= borrowAmountPlusInterestRateUSD) {
                    break; // F:[CM-36]
                }
            }

            unchecked {
                ++i;
            }
        }

        // Require Hf > 1
        if (total < borrowAmountPlusInterestRateUSD)
            revert NotEnoughCollateralException();

        //  F:[CM-34]

        fastCheckCounter[creditAccount] = 1; //  F:[CM-37]
    }

    /// @dev Computes all close parameters based on data
    /// @param totalValue Credit account total value
    /// @param isLiquidated True if calculations needed for liquidation
    /// @param borrowedAmount Credit account borrow amount
    /// @param borrowedAmountWithInterest Credit account borrow amount + interest rate accrued
    function calcClosePayments(
        uint256 totalValue,
        bool isLiquidated,
        uint256 borrowedAmount,
        uint256 borrowedAmountWithInterest
    )
        public
        view
        override
        returns (
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        )
    {
        amountToPool =
            borrowedAmountWithInterest +
            ((borrowedAmountWithInterest - borrowedAmount) * feeInterest) /
            PERCENTAGE_FACTOR; // F:[CM-11, 12, 14, 38]

        if (isLiquidated) {
            // LIQUIDATION CASE
            uint256 totalFunds = (totalValue * liquidationDiscount) /
                PERCENTAGE_FACTOR; // F:[CM-13, 14, 38]

            amountToPool += (totalValue * feeLiquidation) / PERCENTAGE_FACTOR; // F:[CM-14, 38]

            unchecked {
                if (totalFunds > amountToPool) {
                    remainingFunds = totalFunds - amountToPool - 1; // F:[CM-14, 38]
                } else {
                    amountToPool = totalFunds; // F:[CM-13, 38]
                }

                if (totalFunds >= borrowedAmountWithInterest) {
                    profit = amountToPool - borrowedAmountWithInterest; // F:[CM-14, 38]
                } else {
                    loss = borrowedAmountWithInterest - amountToPool; // F:[CM-13, 38]
                }
            }
        } else {
            // CLOSURE CASE
            unchecked {
                profit = amountToPool - borrowedAmountWithInterest; // F:[CM-11, 12, 38]
            }
        }
    }

    /// @dev Transfers all assets from borrower credit account to "to" account and converts WETH => ETH if applicable
    /// @param creditAccount  Credit account address
    /// @param to Address to transfer all assets to
    function _transferAssetsTo(
        address creditAccount,
        address to,
        bool convertWETH
    ) internal {
        uint256 tokenMask;
        uint256 enabledTokensMask = enabledTokensMap[creditAccount];
        if (to == address(0)) revert ZeroAddressException(); // F:[CM-39]

        uint256 count = allowedTokens.length;
        for (uint256 i = 1; i < count; ) {
            tokenMask = 1 << i;

            if (enabledTokensMask & tokenMask > 0) {
                address token = allowedTokens[i];
                uint256 amount = IERC20(token).balanceOf(creditAccount);
                if (amount > 2) {
                    unchecked {
                        _safeTokenTransfer(
                            creditAccount,
                            token,
                            to,
                            amount - 1, // Michael Egorov gas efficiency trick
                            convertWETH
                        ); // F:[CM-40]
                    }
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Transfers token to particular address from credit account and converts WETH => ETH if applicable
    /// @param creditAccount Address of credit account
    /// @param token Token address
    /// @param to Address to transfer asset
    /// @param amount Amount to be transferred
    function _safeTokenTransfer(
        address creditAccount,
        address token,
        address to,
        uint256 amount,
        bool convertToETH
    ) internal {
        if (token == wethAddress && convertToETH) {
            ICreditAccount(creditAccount).safeTransfer(
                token,
                wethGateway,
                amount
            ); // F:[CM-41]
            IWETHGateway(wethGateway).unwrapWETH(to, amount); // F:[CM-41]
        } else {
            ICreditAccount(creditAccount).safeTransfer(token, to, amount); // F:[CM-41]
        }
    }

    /// @dev Checks that token is in allowed list and updates enabledTokenMask
    /// for provided credit account if needed
    /// @param creditAccount Address of credit account
    /// @param token Address of token to be checked
    function _checkAndEnableToken(address creditAccount, address token)
        internal
    {
        // revertIfTokenNotAllowed(token);
        uint256 tokenMask = tokenMasksMap[token]; // F:[CM-27, 28]

        if (tokenMask == 0 || forbiddenTokenMask & tokenMask > 0)
            revert TokenNotAllowedException(); // F:[CM-27]

        if (enabledTokensMap[creditAccount] & tokenMask == 0) {
            enabledTokensMap[creditAccount] |= tokenMask; // F:[CM-28]
        }
    }

    /// @dev It switching resposible bit in enableTokesMask to exclude token
    /// from collateral calculations (for gas efficiency purpose)
    function _disableToken(address creditAccount, address token) internal {
        uint256 tokenMask = tokenMasksMap[token];

        // Both cases in F:[CM-42]
        if (enabledTokensMap[creditAccount] & tokenMask > 0) {
            enabledTokensMap[creditAccount] ^= tokenMask; // F:[CM-42]
        }
    }

    //
    // GETTERS
    //

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        public
        view
        override
        returns (address result)
    {
        result = creditAccounts[borrower]; // F:[CM-43]
        if (result == address(0)) revert HasNoOpenedAccountException(); // F:[CM-43]
    }

    /// @dev Calculates credit account interest accrued
    /// More: https://dev.gearbox.fi/developers/credit/economy#interest-rate-accrued
    ///
    /// @param creditAccount Credit account address
    function calcCreditAccountAccruedInterest(address creditAccount)
        public
        view
        override
        returns (uint256 borrowedAmount, uint256 borrowedAmountWithInterest)
    {
        (
            uint256 _borrowedAmount,
            uint256 cumulativeIndexAtOpen,
            uint256 cumulativeIndexNow
        ) = _getCreditAccountParameters(creditAccount); // F:[CM-44]

        borrowedAmount = _borrowedAmount;
        borrowedAmountWithInterest =
            (borrowedAmount * cumulativeIndexNow) /
            cumulativeIndexAtOpen; // F:[CM-44]
    }

    /// @dev Gets credit account generic parameters
    /// @param creditAccount Credit account address
    /// @return borrowedAmount Amount which pool lent to credit account
    /// @return cumulativeIndexAtOpen Cumulative index at open. Used for interest calculation
    function _getCreditAccountParameters(address creditAccount)
        internal
        view
        returns (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen,
            uint256 cumulativeIndexNow
        )
    {
        borrowedAmount = ICreditAccount(creditAccount).borrowedAmount(); // F:[CM-45]
        cumulativeIndexAtOpen = ICreditAccount(creditAccount)
        .cumulativeIndexAtOpen(); // F:[CM-45]
        cumulativeIndexNow = IPoolService(pool).calcLinearCumulative_RAY(); // F:[CM-45]
    }

    function _safeCreditAccountSet(address borrower, address creditAccount)
        internal
    {
        if (borrower == address(0) || creditAccounts[borrower] != address(0))
            revert ZeroAddressOrUserAlreadyHasAccountException(); // F:[CM-8]
        creditAccounts[borrower] = creditAccount;
    }

    /// @dev Returns quantity of tokens in allowed list
    function allowedTokensCount() external view override returns (uint256) {
        return allowedTokens.length; // F:[CM-46]
    }

    //
    // CONFIGURATION
    //
    // Foloowing functions change core credit manager parameters
    // All this functions could be called by CreditConfigurator only
    //
    function addToken(address token)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        _addToken(token); // F:[CM-47]
    }

    function _addToken(address token) internal {
        if (tokenMasksMap[token] > 0) revert TokenAlreadyAddedException(); // F:[CM-47]
        if (allowedTokens.length >= 256) revert TooMuchTokensException(); // F:[CM-47]
        tokenMasksMap[token] = 1 << allowedTokens.length; // F:[CM-48]
        allowedTokens.push(token); // F:[CM-48]
    }

    /// @dev Sets fees. Restricted for configurator role only

    /// @param _feeInterest Interest fee multiplier
    /// @param _feeLiquidation Liquidation fee multiplier (for totalValue)
    /// @param _liquidationDiscount Liquidation discount multiplier (= PERCENTAGE_FACTOR - liquidation premium)
    function setParams(
        uint256 _minBorrowedAmount,
        uint256 _maxBorrowedAmount,
        uint256 _feeInterest,
        uint256 _feeLiquidation,
        uint256 _liquidationDiscount,
        uint256 _chiThreshold,
        uint256 _hfCheckInterval
    )
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        if (_minBorrowedAmount > _maxBorrowedAmount)
            revert IncorrectLimitsException(); // F:[CM-49]

        minBorrowedAmount = _minBorrowedAmount; // F:[CM-50]
        maxBorrowedAmount = _maxBorrowedAmount; // F:[CM-50]
        feeInterest = _feeInterest; // F:[CM-50]
        feeLiquidation = _feeLiquidation; // F:[CM-50]
        liquidationDiscount = _liquidationDiscount; // F:[CM-50]
        chiThreshold = _chiThreshold; // F:[CM-50]
        hfCheckInterval = _hfCheckInterval; // F:[CM-50]
    }

    function setLiquidationThreshold(
        address token,
        uint256 liquidationThreshold
    )
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        if (tokenMasksMap[token] == 0) revert TokenNotAllowedException(); // F:[CM-51]
        liquidationThresholds[token] = liquidationThreshold; // F:[CM-52]
    }

    /// @dev Forbid token. To allow token one more time use allowToken function
    function setForbidMask(uint256 _forbidMask)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        forbiddenTokenMask = _forbidMask; // F:[CM-53]
    }

    function changeContractAllowance(address adapter, address targetContract)
        external
        creditConfiguratorOnly
    {
        adapterToContract[adapter] = targetContract; // F:[CM-54]
    }

    function upgradeContracts(address _creditFacade, address _priceOracle)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        creditFacade = _creditFacade; // F:[CM-55]
        priceOracle = IPriceOracleV2(_priceOracle); // F:[CM-55]
    }

    function setConfigurator(address _creditConfigurator)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        creditConfigurator = _creditConfigurator; // F:[CM-56]
        emit NewConfigurator(_creditConfigurator); // F:[CM-56]
    }
}
