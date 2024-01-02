// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IELFee {
    function splitFee() external;

    function setELFee(uint elFee) external;

    event SplitFee(uint protocolAmount, uint userAmount);
}
