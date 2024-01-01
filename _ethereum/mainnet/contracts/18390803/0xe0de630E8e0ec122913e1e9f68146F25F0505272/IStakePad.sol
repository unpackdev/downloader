// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./StakePadUtils.sol";

interface IStakePad {
    event NewRewardReceiver(
        uint256 indexed index, address rewardReceiver, address client, address provider, uint96 comission
    );

    function fundValidators(StakePadUtils.BeaconDepositParams[] memory) external payable;

    function deployNewRewardReceiver(address, address, uint96) external;

    function transferOwnership(address) external;

    function owner() external view returns (address);

    function isRegisteredRewardReceiver(address) external view returns (bool);
}
