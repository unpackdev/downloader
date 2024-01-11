// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

interface IStEth {
    function submit(address _referral) external payable returns (uint256);

    function balanceOf(address) external view returns (uint256);
}
