// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

interface ILiquidityPool {
    function updatedBorrowBy(address _borrower) external view returns (uint256);
}
