// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ECDSAUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./PaymentPlanTypes.sol";
import "./IWalletApeCoin.sol";

/// @title Cyan Core Payment Plan V2 Logic
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
library PaymentPlanV2Logic {
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function checkAndCompleteApePlans(
        address cyanWalletAddress,
        address collection,
        uint256 tokenId,
        uint256[2] calldata apePlanIds
    ) external {
        IWalletApeCoin cyanWallet = IWalletApeCoin(cyanWalletAddress);

        _checkAndCompleteApePlan(cyanWallet, apePlanIds[0], collection, tokenId);
        _checkAndCompleteApePlan(cyanWallet, apePlanIds[1], collection, tokenId);
    }

    function _checkAndCompleteApePlan(
        IWalletApeCoin cyanWallet,
        uint256 apePlanId,
        address collection,
        uint256 tokenId
    ) private {
        if (apePlanId == 0) return;

        uint8 apeLockStateBefore = cyanWallet.getApeLockState(collection, tokenId);
        cyanWallet.executeModule(abi.encodeWithSelector(IWalletApeCoin.completeApeCoinPlan.selector, apePlanId));
        uint8 apeLockStateAfter = cyanWallet.getApeLockState(collection, tokenId);

        if (apeLockStateAfter >= apeLockStateBefore) revert InvalidApeCoinPlan();
    }

    /**
     * @notice Return expected payment plan for given price and interest rate
     * @param plan Plan details
     * @return Expected down payment amount
     * @return Expected total interest fee
     * @return Expected total service fee
     * @return Estimated subsequent payments after down payment
     * @return Expected total financing amount
     */
    function getExpectedPlan(Plan calldata plan)
        external
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (plan.totalNumberOfPayments == 0) revert InvalidTotalNumberOfPayments();
        (
            uint256 singleLoanAmount,
            uint256 singleInterestFee,
            uint256 singleServiceFee,
            ,
            uint256 totalInterestFee,
            uint256 totalServiceFee,
            uint256 downPaymentAmount,

        ) = calculatePaymentInfo(plan);
        uint256 totalFinancingAmount = plan.amount + totalInterestFee + totalServiceFee;

        return (
            plan.downPaymentPercent > 0 ? downPaymentAmount + singleServiceFee : 0,
            totalInterestFee,
            totalServiceFee,
            singleLoanAmount + singleInterestFee + singleServiceFee,
            totalFinancingAmount
        );
    }

    function calculatePaymentInfo(Plan memory plan)
        internal
        pure
        returns (
            uint256 singleLoanAmount,
            uint256 singleInterestFee,
            uint256 singleServiceFee,
            uint256 totalLoanAmount,
            uint256 totalInterestFee,
            uint256 totalServiceFee,
            uint256 downPaymentAmount,
            uint8 payCountWithoutDownPayment
        )
    {
        payCountWithoutDownPayment = plan.totalNumberOfPayments - (plan.downPaymentPercent > 0 ? 1 : 0);
        downPaymentAmount = (plan.amount * plan.downPaymentPercent) / 10000;

        totalLoanAmount = plan.amount - downPaymentAmount;
        totalInterestFee = (totalLoanAmount * plan.interestRate) / 10000;
        totalServiceFee = (plan.amount * plan.serviceFeeRate) / 10000;

        singleLoanAmount = totalLoanAmount / payCountWithoutDownPayment;
        singleInterestFee = totalInterestFee / payCountWithoutDownPayment;
        singleServiceFee = totalServiceFee / plan.totalNumberOfPayments;
    }

    /**
     * @notice Return payment info
     * @param plan Plan details
     * @param isEarlyPayment Is paying early
     * @return Remaining payment amount for collateral
     * @return Remaining payment amount for interest fee
     * @return Remaining payment amount for service fee
     * @return Remaining total payment amount
     */
    function getPaymentInfo(Plan memory plan, bool isEarlyPayment)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 loanAmount,
            uint256 interestFee,
            uint256 serviceFee,
            uint256 totalLoanAmount,
            uint256 totalInterestFee,
            uint256 totalServiceFee,
            ,

        ) = calculatePaymentInfo(plan);

        if (isEarlyPayment || (plan.totalNumberOfPayments - plan.counterPaidPayments) == 1) {
            uint8 paidCountWithoutDownPayment = plan.counterPaidPayments - (plan.downPaymentPercent > 0 ? 1 : 0);
            loanAmount = totalLoanAmount - loanAmount * paidCountWithoutDownPayment;
            interestFee = totalInterestFee - interestFee * paidCountWithoutDownPayment;
            serviceFee = totalServiceFee - serviceFee * plan.counterPaidPayments;
        }
        return (loanAmount, interestFee, serviceFee, loanAmount + interestFee + serviceFee);
    }

    function calculateInterestFeeDiscount(
        uint256 baseDiscountRate,
        uint256 interestFee,
        Plan memory plan
    ) internal pure returns (uint256) {
        uint8 remainingNumOfPayments = plan.totalNumberOfPayments - plan.counterPaidPayments;
        if (remainingNumOfPayments <= 1) {
            return interestFee;
        }

        uint256 payCountWithoutDownPayment = plan.totalNumberOfPayments - (plan.downPaymentPercent > 0 ? 1 : 0);
        return (interestFee * baseDiscountRate * remainingNumOfPayments) / (10000 * payCountWithoutDownPayment);
    }

    /**
     * @notice Return true if plan is BNPL by checking status
     * @param status Payment plan status
     * @return Is BNPL
     */
    function isBNPL(PaymentPlanStatus status) internal pure returns (bool) {
        return
            status == PaymentPlanStatus.BNPL_CREATED ||
            status == PaymentPlanStatus.BNPL_FUNDED ||
            status == PaymentPlanStatus.BNPL_ACTIVE ||
            status == PaymentPlanStatus.BNPL_DEFAULTED ||
            status == PaymentPlanStatus.BNPL_REJECTED ||
            status == PaymentPlanStatus.BNPL_COMPLETED ||
            status == PaymentPlanStatus.BNPL_LIQUIDATED;
    }

    function requireCorrectPlanParams(
        Item calldata item,
        Plan calldata plan,
        uint256 signedBlockNum
    ) external view {
        if (item.contractAddress == address(0)) revert InvalidAddress();
        if (item.cyanVaultAddress == address(0)) revert InvalidAddress();
        if (item.itemType < 1 || item.itemType > 3) revert InvalidItem();
        if (item.itemType == 1 && item.amount != 0) revert InvalidItem();
        if (item.itemType == 2 && item.amount == 0) revert InvalidItem();
        if (item.itemType == 3 && item.amount != 0) revert InvalidItem();

        if (signedBlockNum > block.number) revert InvalidBlockNumber();
        if (signedBlockNum + 50 < block.number) revert InvalidSignature();
        if (plan.serviceFeeRate > 300) revert InvalidServiceFeeRate();
        if (plan.amount == 0) revert InvalidTokenPrice();
        if (plan.interestRate == 0) revert InvalidInterestRate();
        if (plan.term == 0) revert InvalidTerm();
    }

    function verifySignature(
        Item calldata item,
        Plan calldata plan,
        uint256 planId,
        uint256 signedBlockNum,
        address signer,
        bytes memory signature
    ) external pure {
        bytes32 itemHash = keccak256(
            abi.encodePacked(item.cyanVaultAddress, item.contractAddress, item.tokenId, item.amount, item.itemType)
        );
        bytes32 planHash = keccak256(
            abi.encodePacked(
                plan.amount,
                plan.downPaymentPercent,
                plan.interestRate,
                plan.serviceFeeRate,
                plan.term,
                plan.totalNumberOfPayments,
                plan.counterPaidPayments,
                plan.autoRepayStatus
            )
        );
        bytes32 msgHash = keccak256(abi.encodePacked(itemHash, planHash, planId, signedBlockNum));
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        if (signedHash.recover(signature) != signer) revert InvalidSignature();
    }

    function verifyRevivalSignature(
        uint256 planId,
        uint256 penaltyAmount,
        uint256 signatureExpiryDate,
        uint8 counterPaidPayments,
        address signer,
        bytes memory signature
    ) external pure {
        bytes32 msgHash = keccak256(abi.encodePacked(planId, penaltyAmount, signatureExpiryDate, counterPaidPayments));
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        if (signedHash.recover(signature) != signer) revert InvalidSignature();
    }
}
