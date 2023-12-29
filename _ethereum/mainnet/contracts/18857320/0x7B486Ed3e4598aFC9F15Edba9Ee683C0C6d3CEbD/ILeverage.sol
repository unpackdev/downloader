// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.20;

import "./IMultiSourceLoan.sol";

interface ILeverage {
    /// @notice Buy a number of NFTs using loans to cover part of the price (i.e. BNPL).
    /// @dev Buy calls emit loan -> Before trying to transfer the NFT but after transfering the principal
    /// @dev Encoded: emitLoan(IMultiSourceLoan.LoanExecutionData)[]
    /// @param _executionData The data needed to execute the loan + buy the NFT.
    function buy(bytes[] calldata _executionData)
        external
        payable
        returns (uint256[] memory, IMultiSourceLoan.Loan[] memory);

    /// @notice Sell the collateral behind a number of loans (potentially 1) and use proceeds to pay back the loans.
    /// @dev Encoded: repayLoan(IMultiSourceLoan.LoanRepaymentData)[]
    /// @param _executionData The data needed to execute the loan repayment + sell the NFT.
    function sell(bytes[] calldata _executionData) external;

    /// @notice First step to update the MultiSourceLoan address.
    /// @param _newAddress The new address of the MultiSourceLoan.
    function updateMultiSourceLoanAddressFirst(address _newAddress) external;

    /// @notice Second step to update the MultiSourceLoan address.
    /// @param _newAddress The new address of the MultiSourceLoan. Must match address from first update.
    function finalUpdateMultiSourceLoanAddress(address _newAddress) external;

    /// @notice Returns the address of the MultiSourceLoan.
    function getMultiSourceLoanAddress() external view returns (address);

    /// @notice First step to update the Seaport address.
    /// @param _newAddress The new address of the Seaport.
    function updateSeaportAddressFirst(address _newAddress) external;

    /// @notice Second step to update the Seaport address.
    /// @param _newAddress The new address of the Seaport.
    function finalUpdateSeaportAddress(address _newAddress) external;

    /// @notice Returns the address of the Seaport.
    function getSeaportAddress() external view returns (address);
}
