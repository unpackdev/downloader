// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ITangoFactory { 
    function withdraw(uint256 _amount, bool _isClaimReward) external;
    function invest4(uint256[4] memory _param) external;
    function secretInvest(address, address, uint256) external;
    function secretWithdraw(address , uint256) external;
    function adminClaimRewardForSCRT(address, address, bytes memory) external;
    function userClaimReward() external;
}