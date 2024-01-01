// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IRewardReceiver {
    event RewardSent(address indexed, uint256);
    event ComissionSent(address indexed, uint256);

    function initialize(address, address, uint96, address) external;

    function transferOwnership(address) external;

    function addValidator(bytes memory) external;

    function getValidators() external returns (bytes[] memory);

    function withdraw() external;

    function proposeNewComission(uint96) external;

    function proposeNewWithdrawalThreshold(uint256) external;

    function cancelNewComission() external;

    function cancelNewWithdrawalThreshold() external;

    function acceptNewComission() external;

    function acceptNewWithdrawalThreshold() external;
}
