// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface ILido {
    function submit(address _referral) external payable returns (uint256);
}
