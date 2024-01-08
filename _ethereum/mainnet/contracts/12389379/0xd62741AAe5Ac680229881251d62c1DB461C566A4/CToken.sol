// SPDX-License-Identifier: BSD-3-Clause
//
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// This contract is copied from https://github.com/compound-finance/compound-protocol
// changelog: updated to use version 0.7.4

pragma solidity 0.7.4;

contract CTokenStorage {
    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    address public comptroller;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;
}

abstract contract CToken is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);
    function approve(address spender, uint amount) external virtual returns (bool);
    function allowance(address owner, address spender) external virtual view returns (uint);
    function balanceOf(address owner) external virtual view returns (uint);
    function balanceOfUnderlying(address owner) external virtual returns (uint);
    function getAccountSnapshot(address account) external virtual view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external virtual view returns (uint);
    function supplyRatePerBlock() external virtual view returns (uint);
    function totalBorrowsCurrent() external virtual returns (uint);
    function borrowBalanceCurrent(address account) external virtual returns (uint);
    function borrowBalanceStored(address account) external virtual view returns (uint);
    function exchangeRateCurrent() external virtual returns (uint);
    function exchangeRateStored() external virtual view returns (uint);
    function getCash() external virtual view returns (uint);
    function accrueInterest() external virtual returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external virtual returns (uint);
}

abstract contract CErc20 is CToken {
    function underlying() external virtual view returns (address);
    function mint(uint mintAmount) external virtual returns (uint);
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
    function repayBorrow(uint repayAmount) external virtual returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CToken cTokenCollateral) external virtual returns (uint);
}

abstract contract CEther is CToken {
    function mint() external virtual payable;
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
    function repayBorrow() external virtual payable;
    function repayBorrowBehalf(address borrower) external virtual payable;
    function liquidateBorrow(address borrower, CToken cTokenCollateral) external virtual payable;
}