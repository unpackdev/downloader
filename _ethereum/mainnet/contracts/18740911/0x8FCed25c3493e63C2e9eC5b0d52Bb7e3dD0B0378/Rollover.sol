// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./IVault.sol";
import "./IFlashLoanRecipient.sol";

import "./IKairos.sol";

import "./Commons.sol";
import "./Objects.sol";
import "./Storage.sol";
import "./Errors.sol";
import "./Erc20CheckedTransfer.sol";
import "./RayMath.sol";

/// @dev we do not use OZ safe approvals wrappers for kairos and balancer as the attack vector addressed by those
///      methos is not relevant here
/// @notice external helper contract leveraging balancer flash loans to allow rollover of loans on kairos
contract Rollover is IFlashLoanRecipient {
    using Erc20CheckedTransfer for IERC20;

    IKairos internal immutable kairos;

    constructor(IKairos _kairos) {
        kairos = _kairos;
    }

    /// @notice extend the duration of an existing loan by switching to a new one without repaying the principal
    /// @param loanId the id of the loan to rollover
    /// @param offerArg arguments for the loan offer to use for the new loan
    /// @return newLoanId the id of the new loan
    /// @dev the collection of the collateral NFT must be approved for all to this contract
    function rollover(uint256 loanId, OfferArg calldata offerArg) external returns (uint256 newLoanId) {
        uint256 amountToRepayOldLoan = kairos.toRepay(loanId);
        Ray kairosFeeRate = kairos.getFeeRateForAsset(offerArg.offer.assetToLend);
        uint256 kairosFee = RayMath.mul(offerArg.amount, kairosFeeRate);
        uint256 receivedAmountFromNewLoan = offerArg.amount - kairosFee;

        Loan memory oldLoan = kairos.getLoan(loanId);
        IERC20 currency = offerArg.offer.assetToLend;
        ForwardedData memory forwardedData = ForwardedData(
            loanId,
            offerArg,
            oldLoan.collateral,
            msg.sender,
            amountToRepayOldLoan,
            receivedAmountFromNewLoan
        );

        if (msg.sender != oldLoan.borrower) {
            revert NotBorrowerOfTheLoan(loanId);
        }

        // reimburse interets / loss of value not covered by the new loan
        if (amountToRepayOldLoan > receivedAmountFromNewLoan) {
            currency.checkedTransferFrom(msg.sender, address(this), amountToRepayOldLoan - receivedAmountFromNewLoan);
        }

        // flow continues in next method, with this contract credited of amountToRepayOldLoan
        BALANCER_VAULT.flashLoan(
            this,
            castToBalIErc20(currency),
            castToUint256Array(amountToRepayOldLoan),
            abi.encode(forwardedData)
        );

        // the nbOfLoans at that time corresponds to the id of the new loan, last created
        (, , newLoanId, ) = kairos.getParameters();
    }

    /// @inheritdoc IFlashLoanRecipient
    /// @dev userData corresponds to dataToForward
    /// @dev we assume that balancer fees on flash loans will stay 0
    function receiveFlashLoan(
        balIErc20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory,
        bytes memory userData
    ) external {
        ForwardedData memory forwardedData = abi.decode(userData, (ForwardedData));
        uint256[] memory singleLoanId = new uint256[](1);
        singleLoanId[0] = forwardedData.loanId;
        OfferArg[] memory singleOfferArg = new OfferArg[](1);
        singleOfferArg[0] = forwardedData.offerArg;
        BorrowArg[] memory singleBorrowArg = new BorrowArg[](1);
        singleBorrowArg[0] = BorrowArg(forwardedData.collateral, singleOfferArg);

        if (msg.sender != address(BALANCER_VAULT)) {
            revert CallerIsNotTheBalancerVault();
        }

        forwardedData.offerArg.offer.assetToLend.approve(address(kairos), forwardedData.amountToRepayOldLoan);

        // repay using flash borrowed funds
        kairos.repay(singleLoanId);

        // get the collateral back from the borrower that previously approved this contract to do so
        forwardedData.collateral.implem.transferFrom(
            forwardedData.borrower,
            address(this),
            forwardedData.collateral.id
        );

        // borrow that gets us the missing funds to repay the flash loan
        forwardedData.collateral.implem.approve(address(kairos), forwardedData.collateral.id);
        uint256 newLoanId = kairos.borrow(singleBorrowArg)[0];

        // the borrower gets his rights on the collateral
        kairos.transferBorrowerRights(newLoanId, forwardedData.borrower);

        // if the NFT gained value since the initial loan, the borrower gets the difference
        if (forwardedData.receivedAmountFromNewLoan > forwardedData.amountToRepayOldLoan) {
            forwardedData.offerArg.offer.assetToLend.checkedTransfer(
                forwardedData.borrower,
                forwardedData.receivedAmountFromNewLoan - forwardedData.amountToRepayOldLoan
            );
        }

        // repay the flash loan
        IERC20(address(tokens[0])).checkedTransfer(address(BALANCER_VAULT), amounts[0]);
    }
}
