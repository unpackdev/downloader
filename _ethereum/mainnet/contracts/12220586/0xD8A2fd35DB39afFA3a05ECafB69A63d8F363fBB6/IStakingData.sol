// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IStakingData {
    function sessionDataOf(address, uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function sessionsOf_(address) external view returns (uint256[] memory);

    function lastSessionIdV1() external view returns (uint256);

    function stepTimestamp() external view returns (uint256);
}
