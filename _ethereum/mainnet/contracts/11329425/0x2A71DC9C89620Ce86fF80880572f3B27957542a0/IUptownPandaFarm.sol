// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";

interface IUptownPandaFarm {
    function startFarming(
        address _upToken,
        address _farmToken,
        uint256 _initialFarmUpSupply
    ) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function harvest() external;

    function claim() external;

    function harvestableReward() external view returns (uint256);

    function claimableHarvestedReward() external view returns (uint256);

    function totalHarvestedReward() external view returns (uint256);
}
