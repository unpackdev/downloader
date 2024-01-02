// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IOperatorVCS {
    function withdrawOperatorRewards(address _receiver, uint256 _amount) external returns (uint256);

    function operatorRewardPercentage() external view returns (uint256);
}
