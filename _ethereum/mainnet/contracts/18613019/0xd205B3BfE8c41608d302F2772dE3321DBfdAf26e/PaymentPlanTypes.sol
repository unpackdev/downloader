// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// DataTypes
enum PaymentPlanStatus {
    BNPL_CREATED,
    BNPL_FUNDED,
    BNPL_ACTIVE,
    BNPL_DEFAULTED,
    BNPL_REJECTED,
    BNPL_COMPLETED,
    BNPL_LIQUIDATED,
    PAWN_ACTIVE,
    PAWN_DEFAULTED,
    PAWN_COMPLETED,
    PAWN_LIQUIDATED
}
struct Plan {
    uint256 amount;
    uint32 downPaymentPercent;
    uint32 interestRate;
    uint32 serviceFeeRate;
    uint32 term;
    uint8 totalNumberOfPayments;
    uint8 counterPaidPayments;
    uint8 autoRepayStatus;
}
struct PaymentPlan {
    Plan plan;
    uint256 createdDate;
    address cyanWalletAddress;
    PaymentPlanStatus status;
}

struct Item {
    uint256 amount;
    uint256 tokenId;
    address contractAddress;
    address cyanVaultAddress;
    // 1 -> ERC721
    // 2 -> ERC1155
    // 3 -> CryptoPunks
    uint8 itemType;
}

// Errors
error InvalidSender();
error InvalidBlockNumber();
error InvalidSignature();
error InvalidServiceFeeRate();
error InvalidTokenPrice();
error InvalidInterestRate();
error InvalidDownPaymentPercent();
error InvalidDownPayment();
error InvalidAmount();
error InvalidTerm();
error InvalidPaidCount();
error InvalidStage();
error InvalidAddress();
error InvalidAutoRepaymentDate();
error InvalidAutoRepaymentStatus();
error InvalidTotalNumberOfPayments();
error InvalidReviveDate();
error InvalidItem();
error InvalidBaseDiscountRate();
error InvalidApeCoinPlan();
error InvalidBendDaoPlan();
error InvalidCurrency();

error EthTransferFailed();

error PaymentPlanAlreadyExists();
error PaymentPlanNotFound();
