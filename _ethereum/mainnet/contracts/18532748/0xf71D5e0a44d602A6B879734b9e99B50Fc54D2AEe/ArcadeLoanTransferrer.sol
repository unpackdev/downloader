// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./INFTLending.sol";
import "./IWETH.sol";
import "./LoanLibrary.sol";
import "./IOriginationController.sol";
import "./ILoanCore.sol";
import "./IRepaymentController.sol";

/// @title Arcade Lending
/// @notice Manages creating and repaying a loan on Arcade
contract ArcadeLoanTransferrer is INFTLending {
    using SafeERC20 for IERC20;

    /// @dev The units of precision equal to the minimum interest of 1 basis point.
    uint256 public constant INTEREST_RATE_DENOMINATOR = 1e18;
    uint256 public constant BASIS_POINTS_DENOMINATOR = 1e4;

    IOriginationController public immutable originationController;
    ILoanCore public immutable loanCore;
    IRepaymentController public immutable repaymentController;
    IWETH public immutable weth;
    address public immutable owner;

    constructor(
        IOriginationController _originationController, 
        ILoanCore _loanCore, 
        IRepaymentController _repaymentController,
        IWETH _weth
    ) {
        originationController = _originationController;
        loanCore = _loanCore;
        repaymentController = _repaymentController;
        weth = _weth;
        owner = msg.sender;
    }


    /// @inheritdoc INFTLending
    function getLoanDetails(
        uint256 _loanId
    ) external view returns (LoanDetails memory loanDetails) {
        LoanLibrary.LoanData memory loanData = loanCore.getLoan(_loanId);

        uint256 repayAmount = getRepayAmount(loanData.terms.principal, loanData.terms.proratedInterestRate);

        return LoanDetails(
            loanData.terms.principal, // borrowAmount
            repayAmount, // repayAmount
            loanData.startDate + loanData.terms.durationSecs, // loanExpiration
            loanData.terms.collateralAddress, // nftAddress
            loanData.terms.collateralId // tokenId
        );
    }

    /// @inheritdoc INFTLending
    function borrow(
        bytes calldata _inputData
    ) external payable returns (uint256 loanId) {
        require(tx.origin == owner, "ArcadeLoanTransferrer: tx.origin is not expected");

        ( uint256 _loanId ) = abi.decode(_inputData, ( uint256 ));
        loanId = _loanId;
    }

    /// @inheritdoc INFTLending
    function repay(uint256 _loanId, address _receiver) external payable {
        // 1. Compute repay amount
        LoanLibrary.LoanData memory loanData = loanCore.getLoan(_loanId);
        uint256 repayAmount = getRepayAmount(loanData.terms.principal, loanData.terms.proratedInterestRate);

        // 2. Wrap ETH into WETH and give permission
        weth.deposit{value: repayAmount}();
        IERC20(loanData.terms.payableCurrency).approve(address(loanCore), repayAmount);

        // 3. Repay loan
        repaymentController.repay(_loanId);

        // 4. Transfer collateral NFT to the user
        if (_receiver != address(this)) {
            IERC721(loanData.terms.collateralAddress).safeTransferFrom(
                address(this),
                _receiver,
                loanData.terms.collateralId
            );
        }
    }

    receive() external payable {}

    /**
     * @notice Calculate the repay amount due over a full term.
     *
     * @param principal                             Principal amount in the loan terms.
     * @param proratedInterestRate                  Interest rate in the loan terms, prorated over loan duration.
     *
     * @return repayAmount                          The amount to repay
     */
    function getRepayAmount(uint256 principal, uint256 proratedInterestRate) public pure returns (uint256) {
        return principal + getInterestAmount(principal, proratedInterestRate);
    }

    /**
     * @notice Calculate the interest due over a full term.
     *
     * @dev Interest and principal must be entered with 18 units of
     *      precision from the basis point unit (e.g. 1e18 == 0.01%)
     *
     * @param principal                             Principal amount in the loan terms.
     * @param proratedInterestRate                  Interest rate in the loan terms, prorated over loan duration.
     *
     * @return interest                             The amount of interest due.
     */
    function getInterestAmount(uint256 principal, uint256 proratedInterestRate) public pure returns (uint256) {
        return principal * proratedInterestRate / (INTEREST_RATE_DENOMINATOR * BASIS_POINTS_DENOMINATOR);
    }
}