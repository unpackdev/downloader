// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IStakingV1 {
    function externalStake(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) external;

    function sessionDataOf(address, uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}
