// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAquaPremium {
    function getAquaPremium() external view returns (uint256);

    function calculatePremium(
        uint256 initiationTimestamp,
        uint256 initialPremium,
        uint256 aquaPoolPremium,
        uint256 aquaAmount
    ) external view returns (uint256, uint256);
}
