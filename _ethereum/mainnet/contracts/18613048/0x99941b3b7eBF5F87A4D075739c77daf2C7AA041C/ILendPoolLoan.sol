// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DataTypes.sol";

interface ILendPoolLoan {
    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);

    function getLoan(uint256 loanId) external view returns (DataTypes.LoanData memory loanData);

    function getLoanReserveBorrowAmount(uint256 loanId) external view returns (address, uint256);
}
