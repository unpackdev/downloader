// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ITangoFactory { 
    function withdraw(uint256 _amount) external;
    function invest4(uint256[4] memory _param) external;
    function invest(address, uint256) external;
    function adminClaimRewardForSCRT(address, bytes memory) external;
    function userClaimReward() external;
}