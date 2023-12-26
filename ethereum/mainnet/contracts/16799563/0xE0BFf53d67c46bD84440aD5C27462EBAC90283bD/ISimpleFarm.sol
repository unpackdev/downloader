// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface ISimpleFarm {
    function farmDeposit(uint256 amount) external;
    function farmWithdraw(uint256 amount) external;
    function earned(address account) external view returns (uint256);
    function claimReward() external;
    function balanceOf(address account) external view returns (uint256);
    function stakingToken() external view returns (address);
    function rewardsToken() external view returns (address);
}
