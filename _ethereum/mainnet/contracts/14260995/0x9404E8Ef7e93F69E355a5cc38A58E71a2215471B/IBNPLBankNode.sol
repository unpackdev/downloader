// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./IStakedToken.sol";
import "./IAaveLendingPool.sol";
import "./IAaveIncentivesController.sol";

import "./IMintableBurnableTokenUpgradeable.sol";
import "./IBNPLSwapMarket.sol";
import "./IBankNodeManager.sol";

import "./BNPLKYCStore.sol";
import "./IBNPLNodeStakingPool.sol";

/// @dev Interface of the IBNPLBankNode standard
/// @author BNPL
interface IBankNodeInitializableV1 {
    struct BankNodeInitializeArgsV1 {
        uint32 bankNodeId; // The id of bank node
        uint24 bnplSwapMarketPoolFee; // The configured swap market fee
        address bankNodeManager; // The address of bank node manager
        address operatorAdmin; // The admin with `OPERATOR_ADMIN_ROLE` role
        address operator; // The admin with `OPERATOR_ROLE` role
        address bnplToken; // BNPL token address
        address bnplSwapMarket; // The swap market contract (ex. Sushiswap Router)
        uint16 unusedFundsLendingMode; // Lending mode (1)
        address unusedFundsLendingContract; // Lending contract (ex. AAVE lending pool)
        address unusedFundsLendingToken; // (ex. aTokens)
        address unusedFundsIncentivesController; // (ex. AAVE incentives controller)
        address nodeStakingPool; // The staking pool of bank node
        address baseLiquidityToken; // Liquidity token contract (ex. USDT)
        address poolLiquidityToken; // Pool liquidity token contract (ex. Pool USDT)
        address nodePublicKey; // Bank node KYC public key
        uint32 kycMode; // kycMode Bank node KYC mode
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
    function initialize(BankNodeInitializeArgsV1 calldata bankNodeInitConfig) external;
}

/**
 * @dev Interface of the IBNPLBankNode standard
 */
interface IBNPLBankNode is IBankNodeInitializableV1 {
    struct Loan {
        address borrower;
        uint256 loanAmount;
        uint64 totalLoanDuration;
        uint32 numberOfPayments;
        uint64 loanStartedAt;
        uint32 numberOfPaymentsMade;
        uint256 amountPerPayment;
        uint256 interestRatePerPayment;
        uint256 totalAmountPaid;
        uint256 remainingBalance;
        uint8 status; // 0 = ongoing, 1 = completed, 2 = overdue, 3 = written off
        uint64 statusUpdatedAt;
        uint256 loanRequestId;
    }

    /// @dev Get lending mode (1)
    /// @return lendingMode
    function unusedFundsLendingMode() external view returns (uint16);

    /// @notice AAVE lending pool contract address
    /// @return AaveLendingPool
    function unusedFundsLendingContract() external view returns (IAaveLendingPool);

    /// @notice AAVE tokens contract
    /// @return LendingToken
    function unusedFundsLendingToken() external view returns (IERC20);

    /// @notice AAVE incentives controller contract
    /// @return AaveIncentivesController
    function unusedFundsIncentivesController() external view returns (IAaveIncentivesController);

    /// @notice The configured lendable token swap market contract (ex. SushiSwap Router)
    /// @return BNPLSwapMarket
    function bnplSwapMarket() external view returns (IBNPLSwapMarket);

    /// @notice The configured swap market fee
    /// @return bnplSwapMarketPoolFee
    function bnplSwapMarketPoolFee() external view returns (uint24);

    /// @notice The id of bank node
    /// @return bankNodeId
    function bankNodeId() external view returns (uint32);

    /// @notice Returns total assets value of bank node
    /// @return poolTotalAssetsValue
    function getPoolTotalAssetsValue() external view returns (uint256);

    /// @notice Returns total liquidity assets value of bank node (Exclude `accountsReceivableFromLoans`)
    /// @return poolTotalLiquidAssetsValue
    function getPoolTotalLiquidAssetsValue() external view returns (uint256);

    /// @notice The staking pool proxy contract
    /// @return BNPLNodeStakingPool
    function nodeStakingPool() external view returns (IBNPLNodeStakingPool);

    /// @notice The bank node manager proxy contract
    /// @return BankNodeManager
    function bankNodeManager() external view returns (IBankNodeManager);

    /// @notice Liquidity token (ex. USDT) balance of this
    /// @return baseTokenBalance
    function baseTokenBalance() external view returns (uint256);

    /// @notice Returns `unusedFundsLendingToken` (ex. AAVE aTokens) balance of this
    /// @return unusedFundsLendingTokenBalance AAVE aTokens balance of this
    function getValueOfUnusedFundsLendingDeposits() external view returns (uint256);

    /// @notice The balance of bank node admin
    /// @return nodeOperatorBalance
    function nodeOperatorBalance() external view returns (uint256);

    /// @notice Accounts receivable from loans
    /// @return accountsReceivableFromLoans
    function accountsReceivableFromLoans() external view returns (uint256);

    /// @notice Pool liquidity tokens (ex. Pool USDT) circulating
    /// @return poolTokensCirculating
    function poolTokensCirculating() external view returns (uint256);

    /// @notice Current loan request index (pending)
    /// @return loanRequestIndex
    function loanRequestIndex() external view returns (uint256);

    /// @notice Number of loans in progress
    /// @return onGoingLoanCount
    function onGoingLoanCount() external view returns (uint256);

    /// @notice Current loan index (approved)
    /// @return loanIndex
    function loanIndex() external view returns (uint256);

    /// @notice The total amount of all activated loans
    /// @return totalAmountOfActiveLoans
    function totalAmountOfActiveLoans() external view returns (uint256);

    /// @notice The total amount of all loans
    /// @return totalAmountOfLoans
    function totalAmountOfLoans() external view returns (uint256);

    /// @notice Liquidity token contract (ex. USDT)
    /// @return baseLiquidityToken
    function baseLiquidityToken() external view returns (IERC20);

    /// @notice Pool liquidity token contract (ex. Pool USDT)
    /// @return poolLiquidityToken
    function poolLiquidityToken() external view returns (IMintableBurnableTokenUpgradeable);

    /// @notice [Loan id] => [Interest paid for]
    ///
    /// @param loanId The id of loan
    /// @return interestPaidForLoan
    function interestPaidForLoan(uint256 loanId) external view returns (uint256);

    /// @notice The total loss amount of bank node
    /// @return totalLossAllTime
    function totalLossAllTime() external view returns (uint256);

    /// @notice Cumulative value of donate amounts
    /// @return totalDonatedAllTime
    function totalDonatedAllTime() external view returns (uint256);

    /// @notice The total amount of net earnings
    /// @return netEarnings
    function netEarnings() external view returns (uint256);

    /// @notice The total number of loans defaulted
    /// @return totalLoansDefaulted
    function totalLoansDefaulted() external view returns (uint256);

    /// @notice Get bank node KYC public key
    /// @return nodeKycPublicKey
    function nodePublicKey() external view returns (address);

    /// @notice Get bank node KYC mode
    /// @return kycMode
    function kycMode() external view returns (uint256);

    /// @notice The corresponding id in the BNPL KYC store
    /// @return kycDomainId
    function kycDomainId() external view returns (uint32);

    /// @notice The BNPL KYC store contract
    /// @return bnplKYCStore
    function bnplKYCStore() external view returns (BNPLKYCStore);

    /// @notice [Loan request id] => [Loan request]
    /// @param _loanRequestId The id of loan request
    function loanRequests(uint256 _loanRequestId)
        external
        view
        returns (
            address borrower,
            uint256 loanAmount,
            uint64 totalLoanDuration,
            uint32 numberOfPayments,
            uint256 amountPerPayment,
            uint256 interestRatePerPayment,
            uint8 status, // 0 = under review, 1 = rejected, 2 = cancelled, 3 = *unused for now*, 4 = approved
            uint64 statusUpdatedAt,
            address statusModifiedBy,
            uint256 interestRate,
            uint256 loanId,
            uint8 messageType, // 0 = plain text, 1 = encrypted with the public key
            string memory message,
            string memory uuid
        );

    /// @notice [Loan id] => [Loan]
    /// @param _loanId The id of loan
    function loans(uint256 _loanId)
        external
        view
        returns (
            address borrower,
            uint256 loanAmount,
            uint64 totalLoanDuration,
            uint32 numberOfPayments,
            uint64 loanStartedAt,
            uint32 numberOfPaymentsMade,
            uint256 amountPerPayment,
            uint256 interestRatePerPayment,
            uint256 totalAmountPaid,
            uint256 remainingBalance,
            uint8 status, // 0 = ongoing, 1 = completed, 2 = overdue, 3 = written off
            uint64 statusUpdatedAt,
            uint256 loanRequestId
        );

    /// @notice Donate `depositAmount` liquidity tokens to bankNode
    /// @param depositAmount Amount of user deposit to liquidity pool
    function donate(uint256 depositAmount) external;

    /// @notice Allow users to add liquidity tokens to liquidity pools.
    /// @dev The user will be issued an equal number of pool tokens
    ///
    /// @param depositAmount Amount of user deposit to liquidity pool
    function addLiquidity(uint256 depositAmount) external;

    /// @notice Allow users to remove liquidity tokens from liquidity pools.
    /// @dev Users need to replace liquidity tokens with the same amount of pool tokens
    ///
    /// @param poolTokensToConsume Amount of user removes from the liquidity pool
    function removeLiquidity(uint256 poolTokensToConsume) external;

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
    ) external;

    /// @notice Deny a loan request with id `loanRequestId`
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param loanRequestId The id of loan request
    function denyLoanRequest(uint256 loanRequestId) external;

    /// @notice Approve a loan request with id `loanRequestId`
    /// - This also sends the lending token requested to the borrower
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param loanRequestId The id of loan request
    function approveLoanRequest(uint256 loanRequestId) external;

    /// @notice Make a loan payment for loan with id `loanId`
    /// - This method will call the swap contract, so `minTokenOut` is required
    ///
    /// @param loanId The id of loan
    /// @param minTokenOut The minimum output token of swap, if the swap result is less than this value, it will fail
    function makeLoanPayment(uint256 loanId, uint256 minTokenOut) external;

    /// @notice Allows users report a loan with id `loanId` as being overdue
    /// - This method will call the swap contract, so `minTokenOut` is required
    ///
    /// @param loanId The id of loan
    /// @param minTokenOut The minimum output token of swap, if the swap result is less than this value, it will fail
    function reportOverdueLoan(uint256 loanId, uint256 minTokenOut) external;

    /// @notice Withdraw `amount` of balance to an address
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param amount Withdraw amount
    /// @param to Receiving address
    function withdrawNodeOperatorBalance(uint256 amount, address to) external;

    /// @notice Change kyc settings of bank node
    /// - Including `setKYCDomainMode` and `setKYCDomainPublicKey`
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param kycMode_ KYC mode
    /// @param nodePublicKey_ Bank node KYC public key
    function setKYCSettings(uint256 kycMode_, address nodePublicKey_) external;

    /// @notice Set KYC mode for specified kycdomain
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @param domain KYC domain
    /// @param mode KYC mode
    function setKYCDomainMode(uint32 domain, uint256 mode) external;

    /// @notice Returns incentives controller reward token (ex. stkAAVE)
    /// @return stakedAAVE
    function rewardToken() external view returns (IStakedToken);

    /// @notice Get reward token (stkAAVE) unclaimed rewards balance of bank node
    /// @return rewardsBalance
    function getRewardsBalance() external view returns (uint256);

    /// @notice Get reward token (stkAAVE) cool down start time of staking pool
    /// @return cooldownStartTimestamp
    function getCooldownStartTimestamp() external view returns (uint256);

    /// @notice Get reward token (stkAAVE) rewards balance of staking pool
    /// @return stakedTokenRewardsBalance
    function getStakedTokenRewardsBalance() external view returns (uint256);

    /// @notice Get reward token (stkAAVE) balance of staking pool
    /// @return stakedTokenBalance
    function getStakedTokenBalance() external view returns (uint256);

    /// @notice Claim lending token interest
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "OPERATOR_ROLE"
    ///
    /// @return lendingTokenInterest
    function claimLendingTokenInterest() external returns (uint256);
}
