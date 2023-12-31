// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IRepaymentController {
    function claim(uint256 loanId) external;
}
