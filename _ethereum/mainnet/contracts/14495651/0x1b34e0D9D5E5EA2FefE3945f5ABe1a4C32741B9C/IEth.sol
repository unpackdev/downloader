// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IEth {
    enum STATE { OPEN, END, CLOSED }
    function transfer(address recipient, uint amount) external payable returns (bool success);
}
