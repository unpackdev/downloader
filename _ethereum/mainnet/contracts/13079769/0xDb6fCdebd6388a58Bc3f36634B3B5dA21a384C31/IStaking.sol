// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "./Ownable.sol";

interface IStaking {
    function manualEpochInit(address[] memory tokens, uint128 epochId) external;
    function getCurrentEpoch() external view returns (uint128);
    function getEpochId(uint timestamp) external view returns (uint); // get epoch id
    function getEpochUserBalance(address user, address token, uint128 epoch) external view returns(uint);
    function getEpochPoolSize(address token, uint128 epoch) external view returns (uint);
    function epoch1Start() external view returns (uint);
    function epochDuration() external view returns (uint);
}