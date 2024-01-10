// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GlobalClaimer {
    function claimAll(
        address tokenOwner,
        uint256[] memory tokenIds,
        uint256 amount
    ) external;

    function depositsOf(address account)
        external
        view
        returns (uint256[] memory);

    function calculateRewards(address account, uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory rewards);
}
