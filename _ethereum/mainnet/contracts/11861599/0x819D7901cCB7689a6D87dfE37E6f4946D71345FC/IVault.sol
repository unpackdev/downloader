// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface ILevelsVault {
    function addPendingRewards(uint _amount) external;
    function stakedLPTokens(uint256 _pid, address _user) external view returns (uint256);
}