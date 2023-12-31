// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILido {
    function submit(address _referral) external payable returns (uint256);

    function balanceOf(address holder) external view returns (uint256);
}
