// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGStakingVault {
    function claimReward(address _token, address _receiver, uint _amount) external;
    function recoverFund(address _token, address _receiver) external;
}
