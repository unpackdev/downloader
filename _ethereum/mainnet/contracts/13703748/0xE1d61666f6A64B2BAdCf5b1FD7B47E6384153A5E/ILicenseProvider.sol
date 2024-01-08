//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ILicenseProvider {
    function setSubscription(address user,uint256 startDate,uint256 subscriptionDays) external;
}