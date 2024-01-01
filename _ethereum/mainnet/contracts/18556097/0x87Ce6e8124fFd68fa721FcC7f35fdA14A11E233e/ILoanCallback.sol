// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.20;

import "./IMultiSourceLoan.sol";

interface ILoanCallback {
    error InvalidCallbackError();

    /// @notice Called by the MSL contract after the principal of loan has been tranfered (when a loan is initiated)
    /// but before it tries to transfer the NFT into escrow.
    /// @param _loan The loan.
    /// @param _fee The origination fee.
    /// @param _executionData Execution data for purchase.
    /// @return The bytes4 magic value.
    function afterPrincipalTransfer(IMultiSourceLoan.Loan memory _loan, uint256 _fee, bytes calldata _executionData)
        external
        returns (bytes4);

    /// @notice Call by the MSL contract after the NFT has been transfered to the borrower repaying the loan, but before
    /// transfering the principal to the lender.
    /// @param _loan The loan.
    /// @param _executionData Execution data for the offer.
    /// @return The bytes4 magic value.
    function afterNFTTransfer(IMultiSourceLoan.Loan memory _loan, bytes calldata _executionData)
        external
        returns (bytes4);
}
