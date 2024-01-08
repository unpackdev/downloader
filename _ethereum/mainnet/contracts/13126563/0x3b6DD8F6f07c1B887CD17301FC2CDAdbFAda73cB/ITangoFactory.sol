// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ITangoFactory { 
    function secretInvest(address, address, uint256) external;
    function secretWithdraw(address , uint256) external;
    function adminClaimRewardForSCRT(address, address, bytes memory) external;
}