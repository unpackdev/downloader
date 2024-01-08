// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2; // solhint-disable-line

import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Exponential.sol";
import "./IterableLoanMap.sol";
import "./IAdapter.sol";
import "./IBtoken.sol";
import "./IFarmingPool.sol";
import "./ITreasuryPool.sol";

contract FarmingPool is Pausable, ReentrancyGuard, IFarmingPool {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Exponential for uint256;
    using IterableLoanMap for IterableLoanMap.RateToLoanMap;

    struct RepaymentDetails {
        uint256 underlyingAssetInvested;
        uint256 profit;
        uint256 taxAmount;
        uint256 depositPrincipal;
        uint256 payableInterest;
        uint256 loanPrincipalToRepay;
        uint256 amountToReceive;
    }

    uint256 public constant ROUNDING_TOLERANCE = 9999999999 wei;
    uint256 public constant NUM_FRACTION_BITS = 64;
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant DAYS_IN_YEAR = 365;
    uint256 public constant SECONDS_IN_YEAR = SECONDS_IN_DAY * DAYS_IN_YEAR;
    // https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
    // slither-disable-next-line too-many-digits
    uint256 public constant INTEREST_RATE_SLOPE_1 = 0x5555555555555555; // 1/3 in unsigned 64.64 fixzed-point number
    // https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-too-similar
    // slither-disable-next-line similar-names,too-many-digits
    uint256 public constant INTEREST_RATE_SLOPE_2 = 0xF0000000000000000; // 15 in unsigned 64.64 fixed-point number
    uint256 public constant INTEREST_RATE_INTEGER_POINT_1 = 10;
    // slither-disable-next-line similar-names
    uint256 public constant INTEREST_RATE_INTEGER_POINT_2 = 25;
    uint256 public constant PERCENT_100 = 100;
    // slither-disable-next-line too-many-digits
    uint256 public constant UTILISATION_RATE_POINT_1 = 0x320000000000000000; // 50% in unsigned 64.64 fixed-point number
    // slither-disable-next-line similar-names,too-many-digits
    uint256 public constant UTILISATION_RATE_POINT_2 = 0x5F0000000000000000; // 95% in unsigned 64.64 fixed-point number

    string public name;
    address public governanceAccount;
    address public underlyingAssetAddress;
    address public btokenAddress;
    address public treasuryPoolAddress;
    address public insuranceFundAddress;
    address public adapterAddress;
    uint256 public leverageFactor;
    uint256 public liquidationPenalty; // as percentage in unsigned integer
    uint256 public taxRate; // as percentage in unsigned integer

    uint256 public totalUnderlyingAsset;
    uint256 public totalInterestEarned;

    mapping(address => uint256) private _totalTransferToAdapter;
    mapping(address => IterableLoanMap.RateToLoanMap) private _farmerLoans;
    IterableLoanMap.RateToLoanMap private _poolLoans;

    constructor(
        string memory name_,
        address underlyingAssetAddress_,
        address btokenAddress_,
        address treasuryPoolAddress_,
        address insuranceFundAddress_,
        uint256 leverageFactor_,
        uint256 liquidationPenalty_,
        uint256 taxRate_
    ) {
        require(
            underlyingAssetAddress_ != address(0),
            "0 underlying asset address"
        );
        require(btokenAddress_ != address(0), "0 BToken address");
        require(treasuryPoolAddress_ != address(0), "0 treasury pool address");
        require(
            insuranceFundAddress_ != address(0),
            "0 insurance fund address"
        );
        require(leverageFactor_ >= 1, "leverage factor < 1");
        require(liquidationPenalty_ <= 100, "liquidation penalty > 100%");
        require(taxRate_ <= 100, "tax rate > 100%");

        name = name_;
        governanceAccount = msg.sender;
        underlyingAssetAddress = underlyingAssetAddress_;
        btokenAddress = btokenAddress_;
        treasuryPoolAddress = treasuryPoolAddress_;
        insuranceFundAddress = insuranceFundAddress_;
        leverageFactor = leverageFactor_;
        liquidationPenalty = liquidationPenalty_;
        taxRate = taxRate_;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "unauthorized");
        _;
    }

    function addLiquidity(uint256 amount) external override nonReentrant {
        require(amount > 0, "0 amount");
        require(!paused(), "paused");
        require(
            IERC20(underlyingAssetAddress).balanceOf(msg.sender) >= amount,
            "insufficient underlying asset"
        );

        uint256 utilisationRate =
            ITreasuryPool(treasuryPoolAddress).getUtilisationRate(); // in unsigned 64.64-bit fixed point number
        uint256 integerNominalAnnualRate =
            getBorrowNominalAnnualRate(utilisationRate);
        uint256 transferAmount = amount.mul(leverageFactor);
        _totalTransferToAdapter[msg.sender] = _totalTransferToAdapter[
            msg.sender
        ]
            .add(transferAmount);
        uint256 loanAmount = transferAmount.sub(amount);

        updateLoansForDeposit(
            _farmerLoans[msg.sender],
            integerNominalAnnualRate,
            loanAmount
        );
        updateLoansForDeposit(_poolLoans, integerNominalAnnualRate, loanAmount);

        totalUnderlyingAsset = totalUnderlyingAsset.add(amount);

        IERC20(underlyingAssetAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        ITreasuryPool(treasuryPoolAddress).loan(loanAmount);

        bool isApproved =
            IERC20(underlyingAssetAddress).approve(
                adapterAddress,
                transferAmount
            );
        require(isApproved, "approve failed");
        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
        // slither-disable-next-line reentrancy-events
        uint256 receiveQuantity =
            IAdapter(adapterAddress).depositUnderlyingToken(transferAmount);

        emit AddLiquidity(
            msg.sender,
            underlyingAssetAddress,
            amount,
            receiveQuantity,
            block.timestamp
        );

        IBtoken(btokenAddress).mint(msg.sender, receiveQuantity);
    }

    function removeLiquidity(uint256 requestedAmount)
        external
        override
        nonReentrant
    {
        require(requestedAmount > 0, "0 requested amount");
        require(!paused(), "paused");

        (
            RepaymentDetails memory repaymentDetails,
            uint256 actualAmount,
            uint256 receiveQuantity,
            uint256 actualAmountToReceive,
            uint256 outstandingInterest
        ) = removeLiquidityFor(msg.sender, requestedAmount);

        emit RemoveLiquidity(
            msg.sender,
            underlyingAssetAddress,
            requestedAmount,
            actualAmount,
            receiveQuantity,
            repaymentDetails.loanPrincipalToRepay,
            repaymentDetails.payableInterest,
            repaymentDetails.taxAmount,
            actualAmountToReceive,
            outstandingInterest,
            block.timestamp
        );

        {
            // scope to avoid stack too deep errors
            bool isApproved =
                IERC20(underlyingAssetAddress).approve(
                    treasuryPoolAddress,
                    repaymentDetails.loanPrincipalToRepay.add(
                        repaymentDetails.payableInterest
                    )
                );
            require(isApproved, "approve failed");
        }

        ITreasuryPool(treasuryPoolAddress).repay(
            repaymentDetails.loanPrincipalToRepay,
            repaymentDetails.payableInterest
        );
        IBtoken(btokenAddress).burn(msg.sender, actualAmount);
        IERC20(underlyingAssetAddress).safeTransfer(
            insuranceFundAddress,
            repaymentDetails.taxAmount
        );
        IERC20(underlyingAssetAddress).safeTransfer(
            msg.sender,
            actualAmountToReceive
        );
    }

    function liquidate(address account)
        external
        override
        nonReentrant
        onlyBy(governanceAccount)
    {
        require(account != address(0), "0 account");

        uint256 farmerBtokenBalance = IBtoken(btokenAddress).balanceOf(account);
        require(farmerBtokenBalance > 0, "insufficient BToken");

        (
            RepaymentDetails memory repaymentDetails,
            uint256 actualAmount,
            uint256 receiveQuantity,
            uint256 actualAmountToReceive,
            uint256 outstandingInterest
        ) = removeLiquidityFor(account, farmerBtokenBalance);

        uint256 penalty =
            actualAmountToReceive.mul(liquidationPenalty).div(PERCENT_100);
        uint256 finalAmountToReceive = actualAmountToReceive.sub(penalty);

        emit LiquidateFarmer(
            msg.sender,
            underlyingAssetAddress,
            account,
            farmerBtokenBalance,
            actualAmount,
            receiveQuantity,
            repaymentDetails.loanPrincipalToRepay,
            repaymentDetails.payableInterest,
            repaymentDetails.taxAmount,
            penalty,
            finalAmountToReceive,
            outstandingInterest,
            block.timestamp
        );

        {
            // scope to avoid stack too deep errors
            bool isApproved =
                IERC20(underlyingAssetAddress).approve(
                    treasuryPoolAddress,
                    repaymentDetails.loanPrincipalToRepay.add(
                        repaymentDetails.payableInterest
                    )
                );
            require(isApproved, "approve failed");
        }

        ITreasuryPool(treasuryPoolAddress).repay(
            repaymentDetails.loanPrincipalToRepay,
            repaymentDetails.payableInterest
        );
        IBtoken(btokenAddress).burn(account, actualAmount);
        IERC20(underlyingAssetAddress).safeTransfer(
            insuranceFundAddress,
            repaymentDetails.taxAmount.add(penalty)
        );
        IERC20(underlyingAssetAddress).safeTransfer(
            account,
            finalAmountToReceive
        );
    }

    function computeBorrowerInterestEarning()
        external
        override
        onlyBy(treasuryPoolAddress)
        returns (uint256 borrowerInterestEarning)
    {
        require(!paused(), "paused");

        (
            ,
            uint256[] memory poolIntegerInterestRates,
            IterableLoanMap.Loan[] memory poolSortedLoans
        ) = accrueInterestForLoan(_poolLoans);

        require(
            poolIntegerInterestRates.length == poolSortedLoans.length,
            "pool len diff"
        );

        borrowerInterestEarning = getInterestEarning(poolSortedLoans);

        updateLoansForPoolComputeInterest(
            poolIntegerInterestRates,
            poolSortedLoans
        );

        emit ComputeBorrowerInterestEarning(
            borrowerInterestEarning,
            block.timestamp
        );
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(newGovernanceAccount != address(0), "0 governance account");

        governanceAccount = newGovernanceAccount;
    }

    function setTreasuryPoolAddress(address newTreasuryPoolAddress)
        external
        onlyBy(governanceAccount)
    {
        require(
            newTreasuryPoolAddress != address(0),
            "0 treasury pool address"
        );

        treasuryPoolAddress = newTreasuryPoolAddress;
    }

    function setAdapterAddress(address newAdapterAddress)
        external
        onlyBy(governanceAccount)
    {
        require(newAdapterAddress != address(0), "0 adapter address");

        adapterAddress = newAdapterAddress;
    }

    function setLiquidationPenalty(uint256 liquidationPenalty_)
        external
        onlyBy(governanceAccount)
    {
        require(liquidationPenalty_ <= 100, "liquidation penalty > 100%");

        liquidationPenalty = liquidationPenalty_;
    }

    function pause() external onlyBy(governanceAccount) {
        _pause();
    }

    function unpause() external onlyBy(governanceAccount) {
        _unpause();
    }

    function getTotalTransferToAdapterFor(address account)
        external
        view
        override
        returns (uint256 totalTransferToAdapter)
    {
        require(account != address(0), "zero account");

        totalTransferToAdapter = _totalTransferToAdapter[account];
    }

    function getLoansAtLastAccrualFor(address account)
        external
        view
        override
        returns (
            uint256[] memory interestRates,
            uint256[] memory principalsOnly,
            uint256[] memory principalsWithInterest,
            uint256[] memory lastAccrualTimestamps
        )
    {
        require(account != address(0), "zero account");

        uint256 numEntries = _farmerLoans[account].length();
        interestRates = new uint256[](numEntries);
        principalsOnly = new uint256[](numEntries);
        principalsWithInterest = new uint256[](numEntries);
        lastAccrualTimestamps = new uint256[](numEntries);

        for (uint256 i = 0; i < numEntries; i++) {
            (uint256 interestRate, IterableLoanMap.Loan memory farmerLoan) =
                _farmerLoans[account].at(i);

            interestRates[i] = interestRate;
            principalsOnly[i] = farmerLoan._principalOnly;
            principalsWithInterest[i] = farmerLoan._principalWithInterest;
            lastAccrualTimestamps[i] = farmerLoan._lastAccrualTimestamp;
        }
    }

    function getPoolLoansAtLastAccrual()
        external
        view
        override
        returns (
            uint256[] memory interestRates,
            uint256[] memory principalsOnly,
            uint256[] memory principalsWithInterest,
            uint256[] memory lastAccrualTimestamps
        )
    {
        uint256 numEntries = _poolLoans.length();
        interestRates = new uint256[](numEntries);
        principalsOnly = new uint256[](numEntries);
        principalsWithInterest = new uint256[](numEntries);
        lastAccrualTimestamps = new uint256[](numEntries);

        for (uint256 i = 0; i < numEntries; i++) {
            (uint256 interestRate, IterableLoanMap.Loan memory poolLoan) =
                _poolLoans.at(i);

            interestRates[i] = interestRate;
            principalsOnly[i] = poolLoan._principalOnly;
            principalsWithInterest[i] = poolLoan._principalWithInterest;
            lastAccrualTimestamps[i] = poolLoan._lastAccrualTimestamp;
        }
    }

    function estimateBorrowerInterestEarning()
        external
        view
        override
        returns (uint256 borrowerInterestEarning)
    {
        (
            ,
            uint256[] memory poolIntegerInterestRates,
            IterableLoanMap.Loan[] memory poolSortedLoans
        ) = accrueInterestForLoan(_poolLoans);

        require(
            poolIntegerInterestRates.length == poolSortedLoans.length,
            "pool len diff"
        );

        borrowerInterestEarning = getInterestEarning(poolSortedLoans);
    }

    function needToLiquidate(address account, uint256 liquidationThreshold)
        external
        view
        override
        returns (
            bool isLiquidate,
            uint256 accountRedeemableUnderlyingTokens,
            uint256 threshold
        )
    {
        require(account != address(0), "zero account");
        uint256 accountBtokenBalance =
            IBtoken(btokenAddress).balanceOf(account);
        require(accountBtokenBalance > 0, "insufficient BToken");

        (
            uint256 farmerOutstandingInterest,
            uint256[] memory farmerIntegerInterestRates,
            IterableLoanMap.Loan[] memory farmerSortedLoans
        ) = accrueInterestForLoan(_farmerLoans[account]);

        require(
            farmerIntegerInterestRates.length == farmerSortedLoans.length,
            "farmer len diff"
        );

        accountRedeemableUnderlyingTokens = IAdapter(adapterAddress)
            .getRedeemableUnderlyingTokensFor(accountBtokenBalance);

        RepaymentDetails memory repaymentDetails =
            calculateRepaymentDetails(
                account,
                accountBtokenBalance,
                accountRedeemableUnderlyingTokens,
                farmerOutstandingInterest
            );

        isLiquidate = false;
        threshold = repaymentDetails
            .loanPrincipalToRepay
            .add(repaymentDetails.taxAmount)
            .add(repaymentDetails.payableInterest)
            .mul(liquidationThreshold.add(PERCENT_100))
            .div(PERCENT_100);
        if (accountRedeemableUnderlyingTokens < threshold) {
            isLiquidate = true;
        }
    }

    /**
     * @dev Returns the borrow nominal annual rate round down to nearest integer
     *
     * @param utilisationRate as percentage in unsigned 64.64-bit fixed point number
     * @return integerInterestRate as percentage round down to nearest integer
     */
    function getBorrowNominalAnnualRate(uint256 utilisationRate)
        public
        pure
        returns (uint256 integerInterestRate)
    {
        // https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
        // slither-disable-next-line too-many-digits
        require(utilisationRate <= 0x640000000000000000, "> 100%");

        if (utilisationRate <= UTILISATION_RATE_POINT_1) {
            integerInterestRate = INTEREST_RATE_INTEGER_POINT_1;
        } else if (utilisationRate < UTILISATION_RATE_POINT_2) {
            uint256 pointSlope =
                utilisationRate.sub(UTILISATION_RATE_POINT_1).mul(
                    INTEREST_RATE_SLOPE_1
                ) >> (NUM_FRACTION_BITS * 2);

            integerInterestRate = pointSlope.add(INTEREST_RATE_INTEGER_POINT_1);
        } else {
            uint256 pointSlope =
                utilisationRate.sub(UTILISATION_RATE_POINT_2).mul(
                    INTEREST_RATE_SLOPE_2
                ) >> (NUM_FRACTION_BITS * 2);

            integerInterestRate = pointSlope.add(INTEREST_RATE_INTEGER_POINT_2);
        }
    }

    /**
     * @dev Returns the accrue per second compound interest, reverts if overflow
     *
     * @param presentValue in wei
     * @param nominalAnnualRate as percentage in unsigned integer
     * @param numSeconds in unsigned integer
     * @return futureValue in wei
     */
    function accruePerSecondCompoundInterest(
        uint256 presentValue,
        uint256 nominalAnnualRate,
        uint256 numSeconds
    ) public pure returns (uint256 futureValue) {
        require(nominalAnnualRate <= 100, "> 100%");

        uint256 exponent =
            numSeconds.mul(
                (
                    ((
                        nominalAnnualRate.add(SECONDS_IN_YEAR.mul(PERCENT_100))
                    ) << NUM_FRACTION_BITS)
                        .div(SECONDS_IN_YEAR.mul(PERCENT_100))
                )
                    .logBase2()
            );

        futureValue =
            exponent.expBase2().mul(presentValue) >>
            NUM_FRACTION_BITS;
    }

    /**
     * @dev Returns the seconds since last accrual
     *
     * @param currentTimestamp in seconds
     * @param lastAccrualTimestamp in seconds
     * @return secondsSinceLastAccrual
     * @return accrualTimestamp in seconds
     */
    function getSecondsSinceLastAccrual(
        uint256 currentTimestamp,
        uint256 lastAccrualTimestamp
    )
        public
        pure
        returns (uint256 secondsSinceLastAccrual, uint256 accrualTimestamp)
    {
        require(
            currentTimestamp >= lastAccrualTimestamp,
            "current before last"
        );

        secondsSinceLastAccrual = currentTimestamp.sub(lastAccrualTimestamp);
        accrualTimestamp = currentTimestamp;
    }

    function accrueInterestForLoan(
        IterableLoanMap.RateToLoanMap storage rateToLoanMap
    )
        private
        view
        returns (
            uint256 outstandingInterest,
            uint256[] memory integerInterestRates,
            IterableLoanMap.Loan[] memory sortedLoans
        )
    {
        bool[] memory interestRateExists = new bool[](PERCENT_100 + 1);
        IterableLoanMap.Loan[] memory loansByInterestRate =
            new IterableLoanMap.Loan[](PERCENT_100 + 1);

        uint256 numEntries = rateToLoanMap.length();
        integerInterestRates = new uint256[](numEntries);
        sortedLoans = new IterableLoanMap.Loan[](numEntries);
        outstandingInterest = 0;

        for (uint256 i = 0; i < numEntries; i++) {
            (
                uint256 integerNominalAnnualRate,
                IterableLoanMap.Loan memory loan
            ) = rateToLoanMap.at(i);

            (uint256 secondsSinceLastAccrual, uint256 accrualTimestamp) =
                getSecondsSinceLastAccrual(
                    block.timestamp,
                    loan._lastAccrualTimestamp
                );

            loan._lastAccrualTimestamp = accrualTimestamp;

            if (
                loan._principalWithInterest > 0 && secondsSinceLastAccrual > 0
            ) {
                loan._principalWithInterest = accruePerSecondCompoundInterest(
                    loan._principalWithInterest,
                    integerNominalAnnualRate,
                    secondsSinceLastAccrual
                );
            }

            outstandingInterest = outstandingInterest
                .add(loan._principalWithInterest)
                .sub(loan._principalOnly);

            loansByInterestRate[integerNominalAnnualRate] = loan;
            interestRateExists[integerNominalAnnualRate] = true;
        }

        uint256 index = 0;
        for (
            uint256 rate = INTEREST_RATE_INTEGER_POINT_1;
            rate <= PERCENT_100;
            rate++
        ) {
            if (interestRateExists[rate]) {
                integerInterestRates[index] = rate;
                sortedLoans[index] = loansByInterestRate[rate];
                index++;
            }
        }
    }

    function accrueInterestBasedOnInterestRates(
        IterableLoanMap.RateToLoanMap storage rateToLoanMap,
        uint256[] memory inIntegerInterestRates
    )
        private
        view
        returns (
            uint256[] memory outIntegerInterestRates,
            IterableLoanMap.Loan[] memory outSortedLoans
        )
    {
        uint256 numEntries = inIntegerInterestRates.length;
        outIntegerInterestRates = new uint256[](numEntries);
        outSortedLoans = new IterableLoanMap.Loan[](numEntries);

        for (uint256 i = 0; i < numEntries; i++) {
            (bool keyExists, IterableLoanMap.Loan memory loan) =
                rateToLoanMap.tryGet(inIntegerInterestRates[i]);

            (uint256 secondsSinceLastAccrual, uint256 accrualTimestamp) =
                getSecondsSinceLastAccrual(
                    block.timestamp,
                    keyExists ? loan._lastAccrualTimestamp : block.timestamp
                );

            loan._lastAccrualTimestamp = accrualTimestamp;

            if (
                loan._principalWithInterest > 0 && secondsSinceLastAccrual > 0
            ) {
                loan._principalWithInterest = accruePerSecondCompoundInterest(
                    loan._principalWithInterest,
                    inIntegerInterestRates[i],
                    secondsSinceLastAccrual
                );
            }

            outIntegerInterestRates[i] = inIntegerInterestRates[i];
            outSortedLoans[i] = loan;
        }
    }

    function calculateRepaymentDetails(
        address farmerAccount,
        uint256 btokenAmount,
        uint256 underlyingAssetQuantity,
        uint256 outstandingInterest
    ) public view returns (RepaymentDetails memory repaymentDetails) {
        uint256 totalTransferToAdapter = _totalTransferToAdapter[farmerAccount];
        // https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply
        // slither-disable-next-line divide-before-multiply
        uint256 underlyingAssetInvested =
            btokenAmount.mul(totalTransferToAdapter).div(
                IBtoken(btokenAddress).balanceOf(farmerAccount)
            );
        repaymentDetails.underlyingAssetInvested = underlyingAssetInvested;

        repaymentDetails.profit = 0;
        repaymentDetails.taxAmount = 0;
        if (underlyingAssetQuantity > underlyingAssetInvested) {
            repaymentDetails.profit = underlyingAssetQuantity.sub(
                underlyingAssetInvested
            );
            repaymentDetails.taxAmount = repaymentDetails
                .profit
                .mul(taxRate)
                .div(PERCENT_100);
        }

        uint256 depositPrincipal = underlyingAssetInvested.div(leverageFactor);
        repaymentDetails.depositPrincipal = depositPrincipal;
        // slither-disable-next-line divide-before-multiply
        repaymentDetails.payableInterest = outstandingInterest
            .mul(underlyingAssetInvested)
            .div(totalTransferToAdapter);
        repaymentDetails.loanPrincipalToRepay = underlyingAssetInvested.sub(
            depositPrincipal
        );

        repaymentDetails.amountToReceive = underlyingAssetQuantity
            .sub(repaymentDetails.loanPrincipalToRepay)
            .sub(repaymentDetails.taxAmount)
            .sub(repaymentDetails.payableInterest);
    }

    function removeLiquidityFor(address account, uint256 requestedAmount)
        private
        returns (
            RepaymentDetails memory repaymentDetails,
            uint256 actualAmount,
            uint256 receiveQuantity,
            uint256 actualAmountToReceive,
            uint256 outstandingInterest
        )
    {
        require(account != address(0), "0 account");
        require(requestedAmount > 0, "0 requested amount");
        uint256 farmerTotalTransferToAdapter = _totalTransferToAdapter[account];
        require(farmerTotalTransferToAdapter > 0, "no transfer");
        require(
            IBtoken(btokenAddress).balanceOf(account) >= requestedAmount,
            "insufficient BToken"
        );

        (
            uint256 farmerOutstandingInterest,
            uint256[] memory farmerIntegerInterestRates,
            IterableLoanMap.Loan[] memory farmerSortedLoans
        ) = accrueInterestForLoan(_farmerLoans[account]);

        outstandingInterest = farmerOutstandingInterest;

        require(
            farmerIntegerInterestRates.length == farmerSortedLoans.length,
            "farmer len diff"
        );

        (
            uint256[] memory poolIntegerInterestRates,
            IterableLoanMap.Loan[] memory poolSortedLoans
        ) =
            accrueInterestBasedOnInterestRates(
                _poolLoans,
                farmerIntegerInterestRates
            );

        require(
            poolIntegerInterestRates.length == poolSortedLoans.length,
            "pool len diff"
        );
        require(
            farmerIntegerInterestRates.length ==
                poolIntegerInterestRates.length,
            "farmer/pool len diff"
        );

        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-2
        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
        (actualAmount, receiveQuantity) = IAdapter(adapterAddress)
            .redeemWrappedToken(requestedAmount);
        require(
            actualAmount <= requestedAmount,
            "actual greater than requested amount"
        );

        repaymentDetails = calculateRepaymentDetails(
            account,
            actualAmount,
            receiveQuantity,
            farmerOutstandingInterest
        );

        _totalTransferToAdapter[account] = farmerTotalTransferToAdapter.sub(
            repaymentDetails.underlyingAssetInvested
        );

        totalInterestEarned = totalInterestEarned.add(
            repaymentDetails.payableInterest
        );

        updateLoansForFarmerAndPoolWithdraw(
            account,
            farmerIntegerInterestRates,
            farmerSortedLoans,
            poolSortedLoans,
            repaymentDetails
        );

        {
            // scope to avoid stack too deep errors
            uint256 underlyingAssetAmount = totalUnderlyingAsset;
            if (
                underlyingAssetAmount < repaymentDetails.depositPrincipal &&
                repaymentDetails.depositPrincipal.sub(underlyingAssetAmount) <
                ROUNDING_TOLERANCE
            ) {
                totalUnderlyingAsset = 0;
            } else {
                totalUnderlyingAsset = underlyingAssetAmount.sub(
                    repaymentDetails.depositPrincipal
                );
            }
        }

        actualAmountToReceive = repaymentDetails.amountToReceive;
        {
            // scope to avoid stack too deep errors
            uint256 farmingPoolUnderlyingAssetBalance =
                IERC20(underlyingAssetAddress).balanceOf(address(this));
            if (
                farmingPoolUnderlyingAssetBalance < actualAmountToReceive &&
                actualAmountToReceive.sub(farmingPoolUnderlyingAssetBalance) <
                ROUNDING_TOLERANCE
            ) {
                actualAmountToReceive = farmingPoolUnderlyingAssetBalance;
            }
        }
    }

    function getInterestEarning(IterableLoanMap.Loan[] memory poolSortedLoans)
        private
        pure
        returns (uint256 interestEarning)
    {
        interestEarning = 0;
        for (uint256 index = 0; index < poolSortedLoans.length; index++) {
            interestEarning = interestEarning
                .add(poolSortedLoans[index]._principalWithInterest)
                .sub(poolSortedLoans[index]._principalOnly);
        }
    }

    function updateLoansForDeposit(
        IterableLoanMap.RateToLoanMap storage loans,
        uint256 integerNominalAnnualRate,
        uint256 loanAmount
    ) private {
        (bool keyExists, IterableLoanMap.Loan memory loan) =
            loans.tryGet(integerNominalAnnualRate);

        uint256 secondsSinceLastAccrual = 0;
        uint256 accrualTimestamp = block.timestamp;
        if (keyExists) {
            (
                secondsSinceLastAccrual,
                accrualTimestamp
            ) = getSecondsSinceLastAccrual(
                block.timestamp,
                loan._lastAccrualTimestamp
            );
        }

        uint256 presentValue = loan._principalWithInterest;
        uint256 futureValue = presentValue;
        if (presentValue > 0 && secondsSinceLastAccrual > 0) {
            futureValue = accruePerSecondCompoundInterest(
                presentValue,
                integerNominalAnnualRate,
                secondsSinceLastAccrual
            );
        }

        loan._principalOnly = loan._principalOnly.add(loanAmount);
        loan._principalWithInterest = futureValue.add(loanAmount);
        loan._lastAccrualTimestamp = accrualTimestamp;

        // https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
        // slither-disable-next-line unused-return
        loans.set(integerNominalAnnualRate, loan);
    }

    function updateLoansForFarmerAndPoolWithdraw(
        address farmerAccount,
        uint256[] memory integerInterestRates,
        IterableLoanMap.Loan[] memory farmerSortedLoans,
        IterableLoanMap.Loan[] memory poolSortedLoans,
        RepaymentDetails memory repaymentDetails
    ) private {
        require(integerInterestRates.length > 0, "integerInterestRates len");
        require(
            farmerSortedLoans.length == integerInterestRates.length,
            "farmerSortedLoans len"
        );
        require(
            poolSortedLoans.length == integerInterestRates.length,
            "poolSortedLoans len"
        );

        uint256 repayPrincipalRemaining = repaymentDetails.loanPrincipalToRepay;
        uint256 repayPrincipalWithInterestRemaining =
            repaymentDetails.loanPrincipalToRepay.add(
                repaymentDetails.payableInterest
            );

        for (uint256 index = integerInterestRates.length; index > 0; index--) {
            if (repayPrincipalRemaining > 0) {
                if (
                    farmerSortedLoans[index - 1]._principalOnly >=
                    repayPrincipalRemaining
                ) {
                    farmerSortedLoans[index - 1]
                        ._principalOnly = farmerSortedLoans[index - 1]
                        ._principalOnly
                        .sub(repayPrincipalRemaining);

                    poolSortedLoans[index - 1]._principalOnly = poolSortedLoans[
                        index - 1
                    ]
                        ._principalOnly
                        .sub(repayPrincipalRemaining);

                    repayPrincipalRemaining = 0;
                } else {
                    poolSortedLoans[index - 1]._principalOnly = poolSortedLoans[
                        index - 1
                    ]
                        ._principalOnly
                        .sub(farmerSortedLoans[index - 1]._principalOnly);

                    repayPrincipalRemaining = repayPrincipalRemaining.sub(
                        farmerSortedLoans[index - 1]._principalOnly
                    );

                    farmerSortedLoans[index - 1]._principalOnly = 0;
                }
            }

            if (repayPrincipalWithInterestRemaining > 0) {
                if (
                    farmerSortedLoans[index - 1]._principalWithInterest >=
                    repayPrincipalWithInterestRemaining
                ) {
                    farmerSortedLoans[index - 1]
                        ._principalWithInterest = farmerSortedLoans[index - 1]
                        ._principalWithInterest
                        .sub(repayPrincipalWithInterestRemaining);

                    if (
                        poolSortedLoans[index - 1]._principalWithInterest <
                        repayPrincipalWithInterestRemaining &&
                        repayPrincipalWithInterestRemaining.sub(
                            poolSortedLoans[index - 1]._principalWithInterest
                        ) <
                        ROUNDING_TOLERANCE
                    ) {
                        poolSortedLoans[index - 1]._principalWithInterest = 0;
                    } else {
                        poolSortedLoans[index - 1]
                            ._principalWithInterest = poolSortedLoans[index - 1]
                            ._principalWithInterest
                            .sub(repayPrincipalWithInterestRemaining);
                    }

                    repayPrincipalWithInterestRemaining = 0;
                } else {
                    if (
                        poolSortedLoans[index - 1]._principalWithInterest <
                        farmerSortedLoans[index - 1]._principalWithInterest &&
                        farmerSortedLoans[index - 1]._principalWithInterest.sub(
                            poolSortedLoans[index - 1]._principalWithInterest
                        ) <
                        ROUNDING_TOLERANCE
                    ) {
                        poolSortedLoans[index - 1]._principalWithInterest = 0;
                    } else {
                        poolSortedLoans[index - 1]
                            ._principalWithInterest = poolSortedLoans[index - 1]
                            ._principalWithInterest
                            .sub(
                            farmerSortedLoans[index - 1]._principalWithInterest
                        );
                    }

                    repayPrincipalWithInterestRemaining = repayPrincipalWithInterestRemaining
                        .sub(
                        farmerSortedLoans[index - 1]._principalWithInterest
                    );

                    farmerSortedLoans[index - 1]._principalWithInterest = 0;
                }
            }

            if (
                farmerSortedLoans[index - 1]._principalOnly > 0 ||
                farmerSortedLoans[index - 1]._principalWithInterest > 0
            ) {
                // https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
                // slither-disable-next-line unused-return
                _farmerLoans[farmerAccount].set(
                    integerInterestRates[index - 1],
                    farmerSortedLoans[index - 1]
                );
            } else {
                // slither-disable-next-line unused-return
                _farmerLoans[farmerAccount].remove(
                    integerInterestRates[index - 1]
                );
            }

            if (
                poolSortedLoans[index - 1]._principalOnly > 0 ||
                poolSortedLoans[index - 1]._principalWithInterest > 0
            ) {
                // slither-disable-next-line unused-return
                _poolLoans.set(
                    integerInterestRates[index - 1],
                    poolSortedLoans[index - 1]
                );
            } else {
                // slither-disable-next-line unused-return
                _poolLoans.remove(integerInterestRates[index - 1]);
            }
        }
    }

    function updateLoansForPoolComputeInterest(
        uint256[] memory integerInterestRates,
        IterableLoanMap.Loan[] memory poolSortedLoans
    ) private {
        require(
            poolSortedLoans.length == integerInterestRates.length,
            "poolSortedLoans len"
        );

        for (uint256 index = 0; index < integerInterestRates.length; index++) {
            if (
                poolSortedLoans[index]._principalOnly > 0 ||
                poolSortedLoans[index]._principalWithInterest > 0
            ) {
                // slither-disable-next-line unused-return
                _poolLoans.set(
                    integerInterestRates[index],
                    poolSortedLoans[index]
                );
            } else {
                // slither-disable-next-line unused-return
                _poolLoans.remove(integerInterestRates[index]);
            }
        }
    }
}
