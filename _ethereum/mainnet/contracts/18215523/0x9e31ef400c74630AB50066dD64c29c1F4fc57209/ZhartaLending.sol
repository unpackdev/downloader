// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./INFTLending.sol";
import "./ILoansPeripheral.sol";
import "./ILoansCore.sol";
import "./IWETH.sol";

/// @title Zharta Lending
/// @notice Manages creating and repaying a loan on Zharta
contract ZhartaLending is INFTLending {
    using SafeERC20 for IERC20;

    /// @notice LoansPeripheral Contract
    ILoansPeripheral public immutable loansPeripheral;

    /// @notice LoansCore Contract
    ILoansCore public immutable loansCore;

    /// @notice Collateral Vault Core
    address public immutable collateralVaultCore;

    constructor(ILoansPeripheral _loansPeripheral, ILoansCore _loansCore, address _collateralVaultCore) {
        loansPeripheral = _loansPeripheral;
        loansCore = _loansCore;
        collateralVaultCore = _collateralVaultCore;
    }

    /// @inheritdoc INFTLending
    function getLoanDetails(
        uint256 _loanId
    ) external view returns (LoanDetails memory loanDetails) {
        // Get Loan for loanId
        ILoansCore.Loan memory loanDetail = loansCore.getLoan(
            msg.sender,
            _loanId
        );

        uint256 repayAmount = loansPeripheral.getLoanPayableAmount(
            msg.sender,
            _loanId,
            block.timestamp
        );

        return LoanDetails(
            loanDetail.amount, // borrowAmount
            repayAmount, // repayAmount
            loanDetail.maturity, // loanExpiration
            loanDetail.collaterals[0].contractAddress, // nftAddress
            loanDetail.collaterals[0].tokenId // tokenId
        );
    }

    /// @notice Get loan details for given loan id and the borrower
    /// @param _loanId The loan id
    /// @param _borrower The borrower
    function getLoanDetailsForBorrower(
        uint256 _loanId,
        address _borrower
    ) external view returns (LoanDetails memory loanDetails) {
        // Get Loan for loanId
        ILoansCore.Loan memory loanDetail = loansCore.getLoan(
            _borrower,
            _loanId
        );

        uint256 repayAmount = loansPeripheral.getLoanPayableAmount(
            _borrower,
            _loanId,
            block.timestamp
        );

        return LoanDetails(
            loanDetail.amount, // borrowAmount
            repayAmount, // repayAmount
            loanDetail.maturity, // loanExpiration
            loanDetail.collaterals[0].contractAddress, // nftAddress
            loanDetail.collaterals[0].tokenId // tokenId
        );
    }

    /// @inheritdoc INFTLending
    function borrow(
        bytes calldata _inputData
    ) external payable returns (uint256) {
        // Decode `inputData` into required parameters
        ILoansPeripheral.Calldata memory callData = abi.decode(
            _inputData,
            (ILoansPeripheral.Calldata)
        );

        IERC721 nft = IERC721(callData.collateral.contractAddress);

        // Approve
        if (!nft.isApprovedForAll(address(this), collateralVaultCore)) {
            nft.setApprovalForAll(collateralVaultCore, true);
        }

        ILoansCore.Collateral[] memory collaterals = new ILoansCore.Collateral[](1);
        collaterals[0] = callData.collateral;

        // Borrow on Zharta
        uint256 loanId = loansPeripheral.reserveEth(
            callData.amount,
            callData.interest,
            callData.maturity,
            collaterals,
            callData.delegations,
            callData.deadline,
            callData.nonce,
            callData.genesisToken,
            callData.v,
            callData.r,
            callData.s
        );

        // Return loan id
        return loanId;
    }

    /// @inheritdoc INFTLending
    function repay(uint256 _loanId, address _receiver) external payable {
        // Pay back loan
        uint256 repayAmount = loansPeripheral.getLoanPayableAmount(
            address(this),
            _loanId,
            block.timestamp
        );
        loansPeripheral.pay{value: repayAmount}(_loanId);

        if (_receiver != address(this)) {
            // Get Loan for loanId
            ILoansCore.Loan memory loanDetail = loansCore.getLoan(
                address(this),
                _loanId
            );

            // Transfer collateral NFT to the user
            IERC721(loanDetail.collaterals[0].contractAddress).safeTransferFrom(
                address(this),
                _receiver,
                loanDetail.collaterals[0].tokenId
            );
        }
    }

    receive() external payable {}
}
