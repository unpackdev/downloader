// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./MWeth.sol";

/**
 * @title MOAR's Maximillion Contract
 */
contract Maximillion {
    /**
     * @notice The default mEther market to repay in
     */
    MWeth public mEther;

    /**
     * @notice Construct a Maximillion to repay max in a MEther market
     */
    constructor(MWeth mEther_) public {
        mEther = mEther_;
    }

    /**
     * @notice msg.sender sends Ether to repay an account's borrow in the mEther market
     * @dev The provided Ether is applied towards the borrow balance, any excess is refunded
     * @param borrower The address of the borrower account to repay on behalf of
     */
    function repayBehalf(address borrower) public payable {
        repayBehalfExplicit(borrower, mEther);
    }

    /**
     * @notice msg.sender sends Ether to repay an account's borrow in a mEther market
     * @dev The provided Ether is applied towards the borrow balance, any excess is refunded
     * @param borrower The address of the borrower account to repay on behalf of
     * @param mEther_ The address of the mEther contract to repay in
     */
    function repayBehalfExplicit(address borrower, MWeth mEther_) public payable {
        uint received = msg.value;
        uint borrows = mEther_.borrowBalanceCurrent(borrower);
        if (received > borrows) {
            mEther_.repayBorrowBehalf{value: borrows}(borrower);
            msg.sender.transfer(received - borrows);
        } else {
            mEther_.repayBorrowBehalf{value: received}(borrower);
        }
    }
}