// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./Ownable.sol";

interface IStaking {
    function getEpochId(uint256 timestamp) external view returns (uint256); // get epoch id

    function getEpochUserBalance(
        address user,
        address token,
        uint128 epoch
    ) external view returns (uint256);

    function getEpochPoolSize(address token, uint128 epoch)
        external
        view
        returns (uint256);

    function epoch1Start() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function getRewardsForEpoch(uint128, address)
        external
        view
        returns (uint256, uint256);
}
