// SPDX-License-Identifier: ISC

pragma solidity 0.6.12;

interface IStakingProxy {
    function initialize(address alphaStaking) external;

    function getTotalStaked() external view returns (uint256);

    function getUnbondingAmount() external view returns (uint256);

    function getLastUnbondingTimestamp() external view returns (uint256);

    function getWithdrawableAmount() external view returns (uint256);

    function isUnbonding() external view returns (bool);

    function withdraw() external returns (uint256);

    function stake(uint256 amount) external;

    function unbond() external;

    function withdrawToken(address token) external;
}
