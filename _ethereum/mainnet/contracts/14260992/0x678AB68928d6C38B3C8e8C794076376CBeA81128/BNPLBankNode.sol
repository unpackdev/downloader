// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IAaveLendingPool.sol";
import "./IAaveIncentivesController.sol";
import "./IStakedToken.sol";

import "./IBNPLBankNode.sol";
import "./IBNPLNodeStakingPool.sol";
import "./IBNPLSwapMarket.sol";
import "./IMintableBurnableTokenUpgradeable.sol";

import "./BankNodeManager.sol";
import "./BNPLKYCStore.sol";

import "./TransferHelper.sol";
import "./BankNodeUtils.sol";

/// @title BNPL BankNode contract
///
/// @notice
/// - Features:
///   **Deposit USDT**
///   **Withdraw USDT**
///   **Donate USDT**
///   **Loan request**
///   **Loan approval/rejected**
///   **Deposit USDT to AAVE**
///   **Withdraw USDT from AAVE**
///   **Claim stkAAVE**
///   **Repayment:**
///     **Swap 20% USDT interests to BNPL in Sushiswap for bonder and staker interest**
///   **Reportoverdue:**
///     **Swap BNPL to USDT in Sushiswap for the slashing functionPlatform**
///   **Claim bank node rewards**
/// @author BNPL
contract BNPLBankNode is Initializable, AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable, IBNPLBankNode {
    /// @dev Emitted when user `user` is adds `depositAmount` of liquidity while receiving `issueAmount` of pool tokens
    event LiquidityAdded(address indexed user, uint256 depositAmount, uint256 poolTokensIssued);

    /// @dev Emitted when user `user` burns `withdrawAmount` of pool tokens while receiving `issueAmount` of pool tokens
    event LiquidityRemoved(address indexed user, uint256 withdrawAmount, uint256 poolTokensConsumed);

    /// @dev Emitted when user `user` donates `donationAmount` of base liquidity tokens to the pool
    event Donation(address indexed user, uint256 donationAmount);

    /// @dev Emitted when user `user` requests a loan of `loanAmount` with a loan request id of loanRequestId
    event LoanRequested(address indexed borrower, uint256 loanAmount, uint256 loanRequestId, string uuid);

    /// @dev Emitted when a node manager `operator` denies a loan request with id `loanRequestId`
    event LoanDenied(address indexed borrower, uint256 loanRequestId, address operator);

    /// @dev Emitted when a node manager `operator` approves a loan request with id `loanRequestId`
    event LoanApproved(
        address indexed borrower,
        uint256 loanRequestId,
        uint256 loanId,
        uint256 loanAmount,
        address operator
    );

    /// @dev Emitted when user `borrower` makes a payment on the loan request with id `loanRequestId`
    event LoanPayment(address indexed borrower, uint256 loanId, uint256 paymentAmount);

    struct LoanRequest {
        address borrower;
        uint256 loanAmount;
        uint64 totalLoanDuration;
        uint32 numberOfPayments;
        uint256 amountPerPayment;
        uint256 interestRatePerPayment;
        uint8 status; // 0 = under review, 1 = rejected, 2 = cancelled, 3 = *unused for now*, 4 = approved
        uint64 statusUpdatedAt;
        address statusModifiedBy;
        uint256 interestRate;
        uint256 loanId;
        uint8 messageType; // 0 = plain text, 1 = encrypted with the public key
        string message;
        string uuid;
    }

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant OPERATOR_ADMIN_ROLE = keccak256("OPERATOR_ADMIN_ROLE");

    uint256 public constant UNUSED_FUNDS_MIN_DEPOSIT_SIZE = 1;

    /// @notice The min loan duration (secs)
    uint256 public constant MIN_LOAN_DURATION = 30 days;
    /// @notice The min loan payment interval (secs)
    uint256 public constant MIN_LOAN_PAYMENT_INTERVAL = 2 days;
    /// @notice The max loan duration (secs)
    uint256 public constant MAX_LOAN_DURATION = 1825 days;
    /// @notice The max loan payment interval (secs)
    uint256 public constant MAX_LOAN_PAYMENT_INTERVAL = 180 days;

    uint32 public constant LENDER_NEEDS_KYC = 1 << 1;
    uint32 public constant BORROWER_NEEDS_KYC = 1 << 2;

    /// @dev `5192296858534827628530496329219840` wei
    uint256 public constant MAX_LOAN_AMOUNT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFF00;
    /// @dev `100000000` wei
    uint256 public constant MIN_LOAN_AMOUNT = 0x5f5e100;

    /// @notice Liquidity token contract (ex. USDT)
    IERC20 public override baseLiquidityToken;
    /// @notice Pool liquidity token contract (ex. Pool USDT)
    IMintableBurnableTokenUpgradeable public override poolLiquidityToken;
    /// @notice BNPL token contract
    IERC20 public bnplToken;

    /// @dev Lending mode (1)
    uint16 public override unusedFundsLendingMode;
    /// @notice AAVE lending pool contract address
    IAaveLendingPool public override unusedFundsLendingContract;
    /// @notice AAVE tokens contract
    IERC20 public override unusedFundsLendingToken;
    /// @notice AAVE incentives controller contract
    IAaveIncentivesController public override unusedFundsIncentivesController;

    /// @notice The configured lendable token swap market contract (ex. SushiSwap Router)
    IBNPLSwapMarket public override bnplSwapMarket;
    /// @notice The configured swap market fee
    uint24 public override bnplSwapMarketPoolFee;

    /// @notice The id of bank node
    uint32 public override bankNodeId;

    /// @notice The staking pool proxy contract
    IBNPLNodeStakingPool public override nodeStakingPool;

    /// @notice The bank node manager proxy contract
    IBankNodeManager public override bankNodeManager;

    /// @notice Liquidity token (ex. USDT) balance of this
    uint256 public override baseTokenBalance;
    /// @notice The balance of bank node admin
    uint256 public override nodeOperatorBalance;
    /// @notice Accounts receivable from loans
    uint256 public override accountsReceivableFromLoans;

    /// @notice Pool liquidity tokens (ex. Pool USDT) circulating
    uint256 public override poolTokensCirculating;

    /// @notice Current loan request index (pending)
    uint256 public override loanRequestIndex;
    /// @notice Number of loans in progress
    uint256 public override onGoingLoanCount;
    /// @notice Current loan index (approved)
    uint256 public override loanIndex;

    /// @notice The total amount of all activated loans
    uint256 public override totalAmountOfActiveLoans;
    /// @notice The total amount of all loans
    uint256 public override totalAmountOfLoans;

    /// @notice [Loan request id] => [Loan request]
    mapping(uint256 => LoanRequest) public override loanRequests;
    /// @notice [Loan id] => [Loan]
    mapping(uint256 => Loan) public override loans;
    /// @notice [Loan id] => [Interest paid for]
    mapping(uint256 => uint256) public override interestPaidForLoan;

    /// @notice The total loss amount of bank node
    uint256 public override totalLossAllTime;
    /// @notice The total number of loans defaulted
    uint256 public override totalLoansDefaulted;
    /// @notice The total amount of net earnings
    uint256 public override netEarnings;

    /// @notice Cumulative value of donate amounts
    uint256 public override totalDonatedAllTime;

    /// @notice The corresponding id in the BNPL KYC store
    uint32 public override kycDomainId;
    /// @notice The BNPL KYC store contract
    BNPLKYCStore public override bnplKYCStore;

    /// @notice Get bank node KYC mode
    /// @return kycMode
    function kycMode() external view override returns (uint256) {
        return bnplKYCStore.domainKycMode(kycDomainId);
    }

    /// @notice Get bank node KYC public key
    /// @return nodeKycPublicKey
    function nodePublicKey() external view override returns (address) {
        return bnplKYCStore.publicKeys(kycDomainId);
    }

    /// @dev BankNode contract is created and initialized by the BankNodeManager contract
    ///
    /// - This contract is called through the proxy.
    ///
    /// @param bankNodeInitConfig BankNode configuration (passed in by BankNodeManager contract)
    ///
    /// `BankNodeInitializeArgsV1` paramerter structure:
    ///
    /// ```solidity
    /// uint32 bankNodeId // The id of bank node
    /// uint24 bnplSwapMarketPoolFee // The configured swap market fee
    /// address bankNodeManager // The address of bank node manager
    /// address operatorAdmin // The admin with `OPERATOR_ADMIN_ROLE` role
    /// address operator // The admin with `OPERATOR_ROLE` role
    /// uint256 bnplToken // BNPL token address
    /// address bnplSwapMarket // The swap market contract (ex. Sushiswap Router)
    /// uint16 unusedFundsLendingMode // Lending mode (1)
    /// address unusedFundsLendingContract // Lending contract (ex. AAVE lending pool)
    /// address unusedFundsLendingToken // (ex. AAVE aTokens)
    /// address unusedFundsIncentivesController // (ex. AAVE incentives controller)
    /// address nodeStakingPool // The staking pool of bank node
    /// address baseLiquidityToken // Liquidity token contract (ex. USDT)
    /// address poolLiquidityToken // Pool liquidity token contract (ex. Pool USDT)
    /// address nodePublicKey // Bank node KYC public key
    /// uint32 // kycMode Bank node KYC mode
    /// ```
    function initialize(BankNodeInitializeArgsV1 calldata bankNodeInitConfig)
        external
        override
        nonReentrant
        initializer
    {
        require(
            bankNodeInitConfig.unusedFundsLendingMode == 1,
            "unused funds lending mode currently only supports aave (1)"
        );

        __Context_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();

        baseLiquidityToken = IERC20(bankNodeInitConfig.baseLiquidityToken);
        poolLiquidityToken = IMintableBurnableTokenUpgradeable(bankNodeInitConfig.poolLiquidityToken);

        bnplToken = IERC20(bankNodeInitConfig.bnplToken);
        unusedFundsLendingMode = bankNodeInitConfig.unusedFundsLendingMode;
        unusedFundsLendingToken = IERC20(bankNodeInitConfig.unusedFundsLendingToken);
        unusedFundsLendingContract = IAaveLendingPool(bankNodeInitConfig.unusedFundsLendingContract);
        unusedFundsIncentivesController = IAaveIncentivesController(bankNodeInitConfig.unusedFundsIncentivesController);

        bnplSwapMarket = IBNPLSwapMarket(bankNodeInitConfig.bnplSwapMarket);

        nodeStakingPool = IBNPLNodeStakingPool(bankNodeInitConfig.nodeStakingPool);
        bankNodeManager = IBankNodeManager(bankNodeInitConfig.bankNodeManager);
        bnplSwapMarketPoolFee = bankNodeInitConfig.bnplSwapMarketPoolFee;
        bankNodeId = bankNodeInitConfig.bankNodeId;

        if (bankNodeInitConfig.operator != address(0)) {
            _setupRole(OPERATOR_ROLE, bankNodeInitConfig.operator);
        }
        if (bankNodeInitConfig.operatorAdmin != address(0)) {
            _setupRole(OPERATOR_ADMIN_ROLE, bankNodeInitConfig.operatorAdmin);
            _setRoleAdmin(OPERATOR_ROLE, OPERATOR_ADMIN_ROLE);
        }
        bnplKYCStore = bankNodeManager.bnplKYCStore();
        kycDomainId = bnplKYCStore.createNewKYCDomain(
            address(this),
            bankNodeInitConfig.nodePublicKey,
            bankNodeInitConfig.kycMode
        );
    }

    /// @notice Returns incentives controller reward token (ex. stkAAVE)
    /// @return stakedAAVE
    function rewardToken() public view override returns (IStakedToken) {
        return IStakedToken(unusedFundsIncentivesController.REWARD_TOKEN());
    }

    /// @notice Returns `unusedFundsLendingToken` (ex. AAVE aTokens) balance of this
    /// @return unusedFundsLendingTokenBalance AAVE aTokens balance of this
    function getValueOfUnusedFundsLendingDeposits() public view override returns (uint256) {
        return unusedFundsLendingToken.balanceOf(address(this));
    }

    /// @notice Returns total assets value of bank node
    /// @return poolTotalAssetsValue
    function getPoolTotalAssetsValue() public view override returns (uint256) {
        return baseTokenBalance + getValueOfUnusedFundsLendingDeposits() + accountsReceivableFromLoans;
    }

    /// @notice Returns total liquidity assets value of bank node (Exclude `accountsReceivableFromLoans`)
    /// @return poolTotalLiquidAssetsValue
    function getPoolTotalLiquidAssetsValue() public view override returns (uint256) {
        return baseTokenBalance + getValueOfUnusedFundsLendingDeposits();
    }

    /// @notice Pool deposit conversion
    ///
    /// @param depositAmount Liquidity token (ex. USDT) amount
    /// @return poolDepositConversion
    function getPoolDepositConversion(uint256 depositAmount) public view returns (uint256) {
        uint256 poolTotalAssetsValue = getPoolTotalAssetsValue();
        return (depositAmount * poolTokensCirculating) / (poolTotalAssetsValue > 0 ? poolTotalAssetsValue : 1);
    }

    /// @notice Pool withdraw conversion
    ///
    /// @param withdrawAmount Pool liquidity token (ex. pUSDT) amount
    /// @return poolWithdrawConversion
    function getPoolWithdrawConversion(uint256 withdrawAmount) public view returns (uint256) {
        return (withdrawAmount * getPoolTotalAssetsValue()) / (poolTokensCirculating > 0 ? poolTokensCirculating : 1);
    }

    /// @notice Returns next due timestamp of loan `loanId`
    ///
    /// @param loanId The id of loan
    /// @return loanNextDueDate Next due timestamp
    function getLoanNextDueDate(uint256 loanId) public view returns (uint64) {
        Loan memory loan = loans[loanId];
        require(loan.loanStartedAt > 0 && loan.numberOfPaymentsMade < loan.numberOfPayments);
        uint256 nextPaymentDate = ((uint256(loan.numberOfPaymentsMade + 1) * uint256(loan.totalLoanDuration)) /
            uint256(loan.numberOfPayments)) + uint256(loan.loanStartedAt);
        return uint64(nextPaymentDate);
    }

    /// @dev Withdraw `amount` of base liquidity token from lending contract to this
    function _withdrawFromAaveToBaseBalance(uint256 amount) private {
        require(amount != 0, "amount cannot be 0");
        uint256 ourAaveBalance = unusedFundsLendingToken.balanceOf(address(this));
        require(amount <= ourAaveBalance, "amount exceeds aave balance!");
        unusedFundsLendingContract.withdraw(address(baseLiquidityToken), amount, address(this));
        baseTokenBalance += amount;
    }

    /// @dev Deposit `amount` of base liquidity token from lending contract to this
    function _depositToAaveFromBaseBalance(uint256 amount) private {
        require(amount != 0, "amount cannot be 0");
        require(amount <= baseTokenBalance, "amount exceeds base token balance!");
        baseTokenBalance -= amount;
        TransferHelper.safeApprove(address(baseLiquidityToken), address(unusedFundsLendingContract), amount);
        unusedFundsLendingContract.deposit(address(baseLiquidityToken), amount, address(this), 0);
    }

    /// @dev Check pool balance, withdraw `amount` of base liquidity token from lending contract to this when `amount` > `baseTokenBalance`
    function _ensureBaseBalance(uint256 amount) private {
        require(amount != 0, "amount cannot be 0");
        require(getPoolTotalLiquidAssetsValue() >= amount, "amount cannot be greater than total liquid asset value");
        if (amount > baseTokenBalance) {
            uint256 balanceDifference = amount - baseTokenBalance;
            _withdrawFromAaveToBaseBalance(balanceDifference);
        }
        require(amount <= baseTokenBalance, "error ensuring base balance");
    }

    /// @dev Deposit base liquidity token from lending contract to this when `baseTokenBalance` >= `UNUSED_FUNDS_MIN_DEPOSIT_SIZE`
    function _processMigrateUnusedFundsToLendingPool() private {
        require(UNUSED_FUNDS_MIN_DEPOSIT_SIZE > 0, "UNUSED_FUNDS_MIN_DEPOSIT_SIZE > 0");
        if (baseTokenBalance >= UNUSED_FUNDS_MIN_DEPOSIT_SIZE) {
            _depositToAaveFromBaseBalance(baseTokenBalance);
        }
    }

    /// @dev Mint `mintAmount` pool tokens for address `user`
    function _mintPoolTokensForUser(address user, uint256 mintAmount) private {
        require(user != address(0) && user != address(this), "invalid user");
        require(mintAmount != 0, "mint amount cannot be 0");
        uint256 newMintTokensCirculating = poolTokensCirculating + mintAmount;
        poolTokensCirculating = newMintTokensCirculating;
        poolLiquidityToken.mint(user, mintAmount);
        require(poolTokensCirculating == newMintTokensCirculating);
    }

    /// @dev Handle donate
    function _processDonation(address sender, uint256 depositAmount) private {
        require(sender != address(0) && sender != address(this), "invalid sender");
        require(depositAmount != 0, "depositAmount cannot be 0");

        require(poolTokensCirculating != 0, "poolTokensCirculating must not be 0");
        TransferHelper.safeTransferFrom(address(baseLiquidityToken), sender, address(this), depositAmount);
        baseTokenBalance += depositAmount;
        totalDonatedAllTime += depositAmount;
        _processMigrateUnusedFundsToLendingPool();

        emit Donation(sender, depositAmount);
    }

    /// @dev Called when `poolTokensCirculating` is 0
    /// @return poolTokensOut
    function _setupLiquidityFirst(address user, uint256 depositAmount) private returns (uint256) {
        require(user != address(0) && user != address(this), "invalid user");
        require(depositAmount != 0, "depositAmount cannot be 0");

        require(poolTokensCirculating == 0, "poolTokensCirculating must be 0");
        uint256 totalAssetValue = getPoolTotalAssetsValue();

        TransferHelper.safeTransferFrom(address(baseLiquidityToken), user, address(this), depositAmount);

        require(poolTokensCirculating == 0, "poolTokensCirculating must be 0");
        require(getPoolTotalAssetsValue() == totalAssetValue, "total asset value must not change");

        baseTokenBalance += depositAmount;
        uint256 newTotalAssetValue = getPoolTotalAssetsValue();
        require(newTotalAssetValue != 0 && newTotalAssetValue >= depositAmount);
        uint256 poolTokensOut = newTotalAssetValue;
        _mintPoolTokensForUser(user, poolTokensOut);
        emit LiquidityAdded(user, depositAmount, poolTokensOut);
        _processMigrateUnusedFundsToLendingPool();
        return poolTokensOut;
    }

    /// @dev Called when `poolTokensCirculating` > 0
    /// @return poolTokensOut
    function _addLiquidityNormal(address user, uint256 depositAmount) private returns (uint256) {
        require(user != address(0) && user != address(this), "invalid user");
        require(depositAmount != 0, "depositAmount cannot be 0");

        require(poolTokensCirculating != 0, "poolTokensCirculating must not be 0");

        TransferHelper.safeTransferFrom(address(baseLiquidityToken), user, address(this), depositAmount);
        require(poolTokensCirculating != 0, "poolTokensCirculating cannot be 0");

        uint256 totalAssetValue = getPoolTotalAssetsValue();
        require(totalAssetValue != 0, "total asset value cannot be 0");
        uint256 poolTokensOut = getPoolDepositConversion(depositAmount);

        baseTokenBalance += depositAmount;
        _mintPoolTokensForUser(user, poolTokensOut);
        emit LiquidityAdded(user, depositAmount, poolTokensOut);
        _processMigrateUnusedFundsToLendingPool();
        return poolTokensOut;
    }

    /// @dev Handle add liquidity
    /// @return poolTokensOut
    function _addLiquidity(address user, uint256 depositAmount) private returns (uint256) {
        require(user != address(0) && user != address(this), "invalid user");
        require(!nodeStakingPool.isNodeDecomissioning(), "BankNode bonded amount is less than 75% of the minimum");

        require(depositAmount != 0, "depositAmount cannot be 0");
        if (poolTokensCirculating == 0) {
            return _setupLiquidityFirst(user, depositAmount);
        } else {
            return _addLiquidityNormal(user, depositAmount);
        }
    }

    /// @dev Handle remove liquidity
    /// @return baseTokensOut
    function _removeLiquidity(address user, uint256 poolTokensToConsume) private returns (uint256) {
        require(user != address(0) && user != address(this), "invalid user");

        require(
            poolTokensToConsume != 0 && poolTokensToConsume <= poolTokensCirculating,
            "poolTokenAmount cannot be 0 or more than circulating"
        );

        require(poolTokensCirculating != 0, "poolTokensCirculating must not be 0");
        require(getPoolTotalAssetsValue() != 0, "total asset value must not be 0");

        uint256 baseTokensOut = getPoolWithdrawConversion(poolTokensToConsume);
        poolTokensCirculating -= poolTokensToConsume;
        _ensureBaseBalance(baseTokensOut);
        require(baseTokenBalance >= baseTokensOut, "base tokens balance must be >= out");
        TransferHelper.safeTransferFrom(address(poolLiquidityToken), user, address(this), poolTokensToConsume);
        baseTokenBalance -= baseTokensOut;
        TransferHelper.safeTransfer(address(baseLiquidityToken), user, baseTokensOut);
        emit LiquidityRemoved(user, baseTokensOut, poolTokensToConsume);
        return baseTokensOut;
    }

    /// @notice Donate `depositAmount` liquidity tokens to bankNode
    /// @param depositAmount Amount of user deposit to liquidity pool
    function donate(uint256 depositAmount) external override nonReentrant {
        require(depositAmount != 0, "depositAmount cannot be 0");
        _processDonation(msg.sender, depositAmount);
    }

    /// @notice Allow users to add liquidity tokens to liquidity pools.
    /// @dev The user will be issued an equal number of pool tokens
    ///
    /// @param depositAmount Amount of user deposit to liquidity pool
    function addLiquidity(uint256 depositAmount) external override nonReentrant {
        require(depositAmount != 0, "depositAmount cannot be 0");
        require(
            bnplKYCStore.checkUserBasicBitwiseMode(kycDomainId, msg.sender, LENDER_NEEDS_KYC) == 1,
            "lender needs kyc"
        );

        _addLiquidity(msg.sender, depositAmount);
    }

    /// @notice Allow users to remove liquidity tokens from liquidity pools.
    /// @dev Users need to replace liquidity tokens with the same amount of pool tokens
    ///
    /// @param poolTokensToConsume Amount of user removes from the liquidity pool
    function removeLiquidity(uint256 poolTokensToConsume) external override nonReentrant {
        _removeLiquidity(msg.sender, poolTokensToConsume);
    }

    /// @dev Handle request loan
    function _requestLoan(
        address borrower,
        uint256 loanAmount,
        uint64 totalLoanDuration,
        uint32 numberOfPayments,
        uint256 interestRatePerPayment,
        uint8 messageType,
        string memory message,
        string memory uuid
    ) private {
        require(loanAmount <= MAX_LOAN_AMOUNT && loanAmount >= MIN_LOAN_AMOUNT && interestRatePerPayment > 0);

        uint256 amountPerPayment = BankNodeUtils.getMonthlyPayment(
            loanAmount,
            interestRatePerPayment,
            numberOfPayments
        );

        require(loanAmount <= (amountPerPayment * uint256(numberOfPayments)), "payments not greater than loan amount!");
        require(
            ((totalLoanDuration / uint256(numberOfPayments)) * uint256(numberOfPayments)) == totalLoanDuration,
            "totalLoanDuration must be a multiple of numberOfPayments"
        );
        require(totalLoanDuration >= MIN_LOAN_DURATION, "must be greater than MIN_LOAN_DURATION");
        require(totalLoanDuration <= MAX_LOAN_DURATION, "must be lower than MAX_LOAN_DURATION");
        require(
            (uint256(totalLoanDuration) / uint256(numberOfPayments)) >= MIN_LOAN_PAYMENT_INTERVAL,
            "must be greater than MIN_LOAN_PAYMENT_INTERVAL"
        );
        require(
            (uint256(totalLoanDuration) / uint256(numberOfPayments)) <= MAX_LOAN_PAYMENT_INTERVAL,
            "must be lower than MAX_LOAN_PAYMENT_INTERVAL"
        );

        uint256 currentLoanRequestId = loanRequestIndex;
        loanRequestIndex += 1;
        LoanRequest storage loanRequest = loanRequests[currentLoanRequestId];
        require(loanRequest.borrower == address(0));
        loanRequest.borrower = borrower;
        loanRequest.loanAmount = loanAmount;
        loanRequest.totalLoanDuration = totalLoanDuration;
        loanRequest.interestRatePerPayment = interestRatePerPayment;

        loanRequest.numberOfPayments = numberOfPayments;
        loanRequest.amountPerPayment = amountPerPayment;
        loanRequest.status = 0;
        loanRequest.messageType = messageType;
        loanRequest.message = message;
        loanRequest.uuid = uuid;
        emit LoanRequested(borrower, loanAmount, currentLoanRequestId, uuid);
    }

    /// @notice Allows users to request a loan from the bank node
    ///
    /// @param loanAmount The loan amount
    /// @param totalLoanDuration The total loan duration (secs)
    /// @param numberOfPayments The number of payments
    /// @param interestRatePerPayment The interest rate per payment
    /// @param messageType 0 = plain text, 1 = encrypted with the public key
    /// @param message Writing detailed messages may increase loan approval rates
    /// @param uuid The `LoanRequested` event contains this uuid for easy identification
    function requestLoan(
        uint256 loanAmount,
        uint64 totalLoanDuration,
        uint32 numberOfPayments,
        uint256 interestRatePerPayment,
        uint8 messageType,
        string memory message,
        string memory uuid
    ) external override nonReentrant {
        require(
            bnplKYCStore.checkUserBasicBitwiseMode(kycDomainId, msg.sender, BORROWER_NEEDS_KYC) == 1,
            "borrower needs kyc"
        );
        _requestLoan(
            msg.sender,
            loanAmount,
            totalLoanDuration,
            numberOfPayments,
            interestRatePerPayment,
            messageType,
            message,
            uuid
        );
    }

    /// @dev Handle approve loan request
    function _approveLoanRequest(address operator, uint256 loanRequestId) private {
        require(loanRequestId < loanRequestIndex, "loan request must exist");
        LoanRequest storage loanRequest = loanRequests[loanRequestId];
        require(loanRequest.borrower != address(0));
        require(loanRequest.status == 0, "loan must not already be approved/rejected");
        require(!nodeStakingPool.isNodeDecomissioning(), "BankNode bonded amount is less than 75% of the minimum");

        uint256 loanAmount = loanRequest.loanAmount;
        require(
            loanAmount <= (loanRequest.amountPerPayment * uint256(loanRequest.numberOfPayments)),
            "payments not greater than loan amount!"
        );
        require(
            ((loanRequest.totalLoanDuration / uint256(loanRequest.numberOfPayments)) *
                uint256(loanRequest.numberOfPayments)) == loanRequest.totalLoanDuration,
            "totalLoanDuration must be a multiple of numberOfPayments"
        );

        require(loanRequest.totalLoanDuration >= MIN_LOAN_DURATION, "must be greater than MIN_LOAN_DURATION");
        require(loanRequest.totalLoanDuration <= MAX_LOAN_DURATION, "must be lower than MAX_LOAN_DURATION");
        require(
            (uint256(loanRequest.totalLoanDuration) / uint256(loanRequest.numberOfPayments)) >=
                MIN_LOAN_PAYMENT_INTERVAL,
            "must be greater than MIN_LOAN_PAYMENT_INTERVAL"
        );
        require(
            (uint256(loanRequest.totalLoanDuration) / uint256(loanRequest.numberOfPayments)) <=
                MAX_LOAN_PAYMENT_INTERVAL,
            "must be lower than MAX_LOAN_PAYMENT_INTERVAL"
        );

        uint256 currentLoanId = loanIndex;
        loanIndex += 1;
        loanRequest.status = 4;
        loanRequest.loanId = currentLoanId;
        loanRequest.statusUpdatedAt = uint64(block.timestamp);
        loanRequest.statusModifiedBy = operator;

        Loan storage loan = loans[currentLoanId];
        require(loan.borrower == address(0));
        loan.borrower = loanRequest.borrower;
        loan.loanAmount = loanAmount;
        loan.totalLoanDuration = loanRequest.totalLoanDuration;
        loan.numberOfPayments = loanRequest.numberOfPayments;
        loan.amountPerPayment = loanRequest.amountPerPayment;
        loan.interestRatePerPayment = loanRequest.interestRatePerPayment;

        loan.loanStartedAt = uint64(block.timestamp);
        loan.numberOfPaymentsMade = 0;
        loan.remainingBalance = uint256(loan.numberOfPayments) * uint256(loan.amountPerPayment);
        loan.status = 0;
        loan.loanRequestId = loanRequestId;

        onGoingLoanCount++;
        totalAmountOfLoans += loanAmount;
        totalAmountOfActiveLoans += loanAmount;

        _ensureBaseBalance(loanAmount);

        baseTokenBalance -= loanAmount;
        accountsReceivableFromLoans += loanAmount;
        TransferHelper.safeTransfer(address(baseLiquidityToken), loan.borrower, loanAmount);
        emit LoanApproved(loan.borrower, loanRequestId, currentLoanId, loanAmount, operator);
    }

    /// @dev Handle deny loan request
    function _denyLoanRequest(address operator, uint256 loanRequestId) private {
        require(loanRequestId < loanRequestIndex, "loan request must exist");
        LoanRequest storage loanRequest = loanRequests[loanRequestId];
        require(loanRequest.borrower != address(0));
        require(loanRequest.status == 0, "loan must not already be approved/rejected");
        loanRequest.status = 1;
        loanRequest.statusUpdatedAt = uint64(block.timestamp);
        loanRequest.statusModifiedBy = operator;
        emit LoanDenied(loanRequest.borrower, loanRequestId, operator);
    }

    /// @notice Deny a loan request with id `loanRequestId`
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param loanRequestId The id of loan request
    function denyLoanRequest(uint256 loanRequestId) external override nonReentrant onlyRole(OPERATOR_ROLE) {
        _denyLoanRequest(msg.sender, loanRequestId);
    }

    /// @notice Approve a loan request with id `loanRequestId`
    /// - This also sends the lending token requested to the borrower
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param loanRequestId The id of loan request
    function approveLoanRequest(uint256 loanRequestId) external override nonReentrant onlyRole(OPERATOR_ROLE) {
        _approveLoanRequest(msg.sender, loanRequestId);
    }

    /// @notice Change kyc settings of bank node
    /// - Including `setKYCDomainMode` and `setKYCDomainPublicKey`
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param kycMode_ KYC mode
    /// @param nodePublicKey_ Bank node KYC public key
    function setKYCSettings(uint256 kycMode_, address nodePublicKey_)
        external
        override
        nonReentrant
        onlyRole(OPERATOR_ROLE)
    {
        bnplKYCStore.setKYCDomainMode(kycDomainId, kycMode_);
        bnplKYCStore.setKYCDomainPublicKey(kycDomainId, nodePublicKey_);
    }

    /// @notice Set KYC mode for specified kycdomain
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param domain KYC domain
    /// @param mode KYC mode
    function setKYCDomainMode(uint32 domain, uint256 mode) external override nonReentrant onlyRole(OPERATOR_ROLE) {
        bnplKYCStore.setKYCDomainMode(domain, mode);
    }

    /// @notice Withdraw `amount` of balance to an address
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param amount Withdraw amount
    /// @param to Receiving address
    function withdrawNodeOperatorBalance(uint256 amount, address to)
        external
        override
        nonReentrant
        onlyRole(OPERATOR_ROLE)
    {
        require(nodeOperatorBalance >= amount, "cannot withdraw more than nodeOperatorBalance");
        _ensureBaseBalance(amount);
        nodeOperatorBalance -= amount;
        TransferHelper.safeTransfer(address(baseLiquidityToken), to, amount);
    }

    /// @dev Swap liquidity token to BNP for staking pool
    function _marketBuyBNPLForStakingPool(uint256 amountInBaseToken, uint256 minTokenOut) private {
        require(amountInBaseToken > 0);
        TransferHelper.safeApprove(address(baseLiquidityToken), address(bnplSwapMarket), amountInBaseToken);
        uint256 amountOut = bnplSwapMarket.swapExactTokensForTokens(
            amountInBaseToken,
            minTokenOut,
            BankNodeUtils.getSwapExactTokensPath(address(baseLiquidityToken), address(bnplToken)),
            address(this),
            block.timestamp
        )[2];
        require(amountOut >= minTokenOut, "swap amount must >= minTokenOut");
        TransferHelper.safeApprove(address(bnplToken), address(nodeStakingPool), amountOut);
        nodeStakingPool.donateNotCountedInTotal(amountOut);
    }

    /// @dev Swap BNPL to liquidity token for slashing
    function _marketSellBNPLForSlashing(uint256 bnplAmount, uint256 minTokenOut) private {
        require(bnplAmount > 0);
        TransferHelper.safeApprove(address(bnplToken), address(bnplSwapMarket), bnplAmount);
        uint256 amountOut = bnplSwapMarket.swapExactTokensForTokens(
            bnplAmount,
            minTokenOut,
            BankNodeUtils.getSwapExactTokensPath(address(bnplToken), address(baseLiquidityToken)),
            address(this),
            block.timestamp
        )[2];
        require(amountOut >= minTokenOut, "swap amount must >= minTokenOut");
        baseTokenBalance += amountOut;
    }

    /// @dev Handle report overdue loan
    function _markLoanAsWriteOff(uint256 loanId, uint256 minTokenOut) private {
        Loan storage loan = loans[loanId];
        require(loan.borrower != address(0));
        require(
            loan.loanStartedAt < uint64(block.timestamp),
            "cannot make the loan payment on same block loan is created"
        );
        require(loan.remainingBalance > 0, "loan must not be paid off");
        require(loan.status == 0 || loan.status != 2, "loan must not be paid off or already overdue");

        require(
            getLoanNextDueDate(loanId) < uint64(block.timestamp - bankNodeManager.loanOverdueGracePeriod()),
            "loan must be overdue"
        );
        require(loan.loanAmount > loan.totalAmountPaid);
        uint256 startPoolTotalAssetValue = getPoolTotalAssetsValue();
        loan.status = 2;

        onGoingLoanCount--;
        totalAmountOfActiveLoans -= loan.loanAmount;
        if (loan.totalAmountPaid >= loan.loanAmount) {
            netEarnings = netEarnings + loan.totalAmountPaid - loan.loanAmount;
        }

        //loan.loanAmount-principalPaidForLoan[loanId]
        //uint256 total3rdPartyInterestPaid = loanBondedAmount[loanId]; // bnpl market buy is the same amount as the amount bonded, this must change if they are not equal
        uint256 interestRecirculated = (interestPaidForLoan[loanId] * 7) / 10; // 10% paid to market buy bnpl, 10% bonded

        uint256 accountsReceivableLoss = loan.loanAmount - (loan.totalAmountPaid - interestPaidForLoan[loanId]);
        accountsReceivableFromLoans -= accountsReceivableLoss;

        uint256 prevBalanceEquivalent = startPoolTotalAssetValue - interestRecirculated;
        totalLossAllTime += prevBalanceEquivalent - getPoolTotalAssetsValue();
        totalLoansDefaulted += 1;
        require(prevBalanceEquivalent > getPoolTotalAssetsValue());
        uint256 poolBalance = nodeStakingPool.getPoolTotalAssetsValue();
        require(poolBalance > 0);
        uint256 slashAmount = BankNodeUtils.calculateSlashAmount(
            prevBalanceEquivalent,
            prevBalanceEquivalent - getPoolTotalAssetsValue(),
            poolBalance
        );
        require(slashAmount > 0);
        nodeStakingPool.slash(slashAmount);
        _marketSellBNPLForSlashing(slashAmount, minTokenOut);

        //uint256 lossAmount = accountsReceivableLoss+amountPaidToBNPLMarketBuy;
    }

    /// @notice Allows users report a loan with id `loanId` as being overdue
    /// - This method will call the swap contract, so `minTokenOut` is required
    ///
    /// @param loanId The id of loan
    /// @param minTokenOut The minimum output token of swap, if the swap result is less than this value, it will fail
    function reportOverdueLoan(uint256 loanId, uint256 minTokenOut) external override nonReentrant {
        _markLoanAsWriteOff(loanId, minTokenOut);
    }

    /// @dev Handle make loan payment
    function _makeLoanPayment(
        address payer,
        uint256 loanId,
        uint256 minTokenOut
    ) private {
        require(loanId < loanIndex, "loan request must exist");

        Loan storage loan = loans[loanId];
        require(loan.borrower != address(0));
        require(
            loan.loanStartedAt < uint64(block.timestamp),
            "cannot make the loan payment on same block loan is created"
        );

        require(
            uint64(block.timestamp - bankNodeManager.loanOverdueGracePeriod()) <= getLoanNextDueDate(loanId),
            "loan is overdue and exceeding the grace period"
        );

        uint256 currentPaymentId = loan.numberOfPaymentsMade;
        require(
            currentPaymentId < loan.numberOfPayments &&
                loan.remainingBalance > 0 &&
                loan.remainingBalance >= loan.amountPerPayment
        );
        uint256 interestAmount = BankNodeUtils.getMonthlyInterestPayment(
            loan.loanAmount,
            loan.interestRatePerPayment,
            loan.numberOfPayments,
            loan.numberOfPaymentsMade + 1
        );
        uint256 holdInterest = (interestAmount * 3) / 10;
        //uint returnInterest = interestAmount - holdInterest;
        uint256 bondedInterest = holdInterest / 3;
        uint256 marketBuyInterest = holdInterest - bondedInterest;

        uint256 amountPerPayment = loan.amountPerPayment;
        require(interestAmount > 0 && bondedInterest > 0 && marketBuyInterest > 0 && amountPerPayment > interestAmount);
        TransferHelper.safeTransferFrom(address(baseLiquidityToken), payer, address(this), amountPerPayment);
        loan.totalAmountPaid += amountPerPayment;
        loan.remainingBalance -= amountPerPayment;
        // rounding errors can sometimes cause this to integer overflow, so we add a Math.min around the accountsReceivableFromLoans update
        accountsReceivableFromLoans -= BankNodeUtils.min(
            amountPerPayment - interestAmount,
            accountsReceivableFromLoans
        );
        interestPaidForLoan[loanId] += interestAmount;
        loan.numberOfPaymentsMade = loan.numberOfPaymentsMade + 1;
        nodeOperatorBalance += bondedInterest;

        baseTokenBalance += amountPerPayment - holdInterest;
        _marketBuyBNPLForStakingPool(marketBuyInterest, minTokenOut);

        if (loan.remainingBalance == 0) {
            loan.status = 1;
            loan.statusUpdatedAt = uint64(block.timestamp);

            onGoingLoanCount--;
            totalAmountOfActiveLoans -= loan.loanAmount;
            if (loan.totalAmountPaid >= loan.loanAmount) {
                netEarnings = netEarnings + loan.totalAmountPaid - loan.loanAmount;
            }
        }
        _processMigrateUnusedFundsToLendingPool();

        emit LoanPayment(loan.borrower, loanId, amountPerPayment);
    }

    /// @notice Make a loan payment for loan with id `loanId`
    /// - This method will call the swap contract, so `minTokenOut` is required
    ///
    /// @param loanId The id of loan
    /// @param minTokenOut The minimum output token of swap, if the swap result is less than this value, it will fail
    function makeLoanPayment(uint256 loanId, uint256 minTokenOut) external override nonReentrant {
        _makeLoanPayment(msg.sender, loanId, minTokenOut);
    }

    /// @dev Returns `unusedFundsLendingToken` as array
    function _dividendAssets() internal view returns (address[] memory) {
        address[] memory assets = new address[](1);
        assets[0] = address(unusedFundsLendingToken);
        return assets;
    }

    /// @notice Get reward token (stkAAVE) unclaimed rewards balance of bank node
    /// @return rewardsBalance
    function getRewardsBalance() external view override returns (uint256) {
        return unusedFundsIncentivesController.getRewardsBalance(_dividendAssets(), address(this));
    }

    /// @notice Get reward token (stkAAVE) cool down start time of staking pool
    /// @return cooldownStartTimestamp
    function getCooldownStartTimestamp() external view override returns (uint256) {
        return rewardToken().stakersCooldowns(address(nodeStakingPool));
    }

    /// @notice Get reward token (stkAAVE) rewards balance of staking pool
    /// @return stakedTokenRewardsBalance
    function getStakedTokenRewardsBalance() external view override returns (uint256) {
        return rewardToken().getTotalRewardsBalance(address(nodeStakingPool));
    }

    /// @notice Get reward token (stkAAVE) balance of staking pool
    /// @return stakedTokenBalance
    function getStakedTokenBalance() external view override returns (uint256) {
        return IERC20(address(rewardToken())).balanceOf(address(nodeStakingPool));
    }

    /// @notice Claim lending token interest
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @return lendingTokenInterest
    function claimLendingTokenInterest() external override onlyRole(OPERATOR_ROLE) nonReentrant returns (uint256) {
        TransferHelper.safeApprove(
            rewardToken().REWARD_TOKEN(),
            address(unusedFundsIncentivesController),
            type(uint256).max
        );
        return
            unusedFundsIncentivesController.claimRewards(
                _dividendAssets(),
                type(uint256).max,
                address(nodeStakingPool)
            );
    }
}
