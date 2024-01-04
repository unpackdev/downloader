pragma solidity ^0.7.4;

import "./PEther.sol";

/**
 * @title DeFiPie's Maximillion Contract
 * @author DeFiPie
 */
contract Maximillion {
    /**
     * @notice The default pEther market to repay in
     */
    PEther public pEther;

    /**
     * @notice Construct a Maximillion to repay max in a PEther market
     */
    constructor(PEther pEther_) {
        pEther = pEther_;
    }

    /**
     * @notice msg.sender sends Ether to repay an account's borrow in the pEther market
     * @dev The provided Ether is applied towards the borrow balance, any excess is refunded
     * @param borrower The address of the borrower account to repay on behalf of
     */
    function repayBehalf(address borrower) public payable {
        repayBehalfExplicit(borrower, pEther);
    }

    /**
     * @notice msg.sender sends Ether to repay an account's borrow in a pEther market
     * @dev The provided Ether is applied towards the borrow balance, any excess is refunded
     * @param borrower The address of the borrower account to repay on behalf of
     * @param pEther_ The address of the pEther contract to repay in
     */
    function repayBehalfExplicit(address borrower, PEther pEther_) public payable {
        uint received = msg.value;
        uint borrows = pEther_.borrowBalanceCurrent(borrower);
        uint totalBorrows = pEther_.totalBorrows();
        if (received > borrows) {
            if (borrows > totalBorrows) {
                borrows = totalBorrows;
            }
            pEther_.repayBorrowBehalf{value: borrows}(borrower);
            msg.sender.transfer(received - borrows);
        } else {
            pEther_.repayBorrowBehalf{value: received}(borrower);
        }
    }
}