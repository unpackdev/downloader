// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./MToken.sol";

interface MErc20Interface {
    /*** User contract ***/
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function borrowFor(address payable borrower, uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, MToken mTokenCollateral) external returns (uint);

    /*** Admin Functions ***/
    function _addReserves(uint addAmount) external returns (uint);
}