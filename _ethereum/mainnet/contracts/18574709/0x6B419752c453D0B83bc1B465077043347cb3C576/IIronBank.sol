// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IERC20.sol";

interface IIronBank is IERC20 {
    // add borrow, repay, etc here
    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function creditLimits(address protocol, address market)
        external
        view
        returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);
}
