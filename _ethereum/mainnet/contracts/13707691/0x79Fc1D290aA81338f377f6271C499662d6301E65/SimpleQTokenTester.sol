// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./QConstant.sol";
pragma experimental ABIEncoderV2;

contract SimpleQTokenTester {
    address public underlying;
    uint public qTokenBalance;
    uint public borrowBalance;
    uint public exchangeRate;
    uint public exchangeRateStored;
    uint public totalBorrow;

    constructor(address _underlying) public {
        underlying = _underlying;
        exchangeRateStored = 50000000000000000;
    }

    function getAccountSnapshot(address)
        public
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        return (qTokenBalance, borrowBalance, exchangeRate);
    }

    function setAccountSnapshot(
        uint _qTokenBalance,
        uint _borrowBalance,
        uint _exchangeRate
    ) public {
        qTokenBalance = _qTokenBalance;
        borrowBalance = _borrowBalance;
        exchangeRate = _exchangeRate;
        totalBorrow = _borrowBalance;
    }

    function borrowBalanceOf(address) public view returns (uint) {
        return borrowBalance;
    }

    function accruedAccountSnapshot(address) external view returns (QConstant.AccountSnapshot memory) {
        QConstant.AccountSnapshot memory snapshot;
        snapshot.qTokenBalance = qTokenBalance;
        snapshot.borrowBalance = borrowBalance;
        snapshot.exchangeRate = exchangeRate;
        return snapshot;
    }

    function accruedTotalBorrow() public view returns (uint) {
        return totalBorrow;
    }

    function accruedBorrowBalanceOf(address) public view returns (uint) {
        return borrowBalance;
    }

    function accruedExchangeRate() public view returns (uint) {
        return exchangeRate;
    }
}
