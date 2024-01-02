// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.19;

contract MockLendingManager {
    mapping(uint16 => uint24) private _epochsTotalBorrowedAmount;

    constructor() {}

    function increaseTotalBorrowedAmountByEpoch(uint24 amount, uint16 epoch) external {
        _epochsTotalBorrowedAmount[epoch] += amount;
    }

    function totalBorrowedAmountByEpoch(uint16 epoch) external view returns (uint24) {
        return _epochsTotalBorrowedAmount[epoch];
    }
}
