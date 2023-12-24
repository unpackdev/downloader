// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IRounds {
    /// @notice Returns the round details of the round numberz
    function rounds(
        uint32 round
    ) external view returns (uint256 startTime, uint256 endTime, uint256 price);
}
