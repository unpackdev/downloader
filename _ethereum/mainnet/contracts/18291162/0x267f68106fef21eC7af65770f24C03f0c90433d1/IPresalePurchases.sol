// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IPresalePurchases {
    function hasClaimed(address _user) external returns(bool);

    function userDeposits(address _user) external returns(uint256);
}
