// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GlobalClaimer {
    function claimAll(
        address tokenOwner,
        uint256[] memory tokenIds,
        uint256 amount
    ) external;

    function depositsOf(address despositer)
        external
        view
        returns (uint256[] memory);

    function calculateReward(address account, uint256 tokenId)
        external
        view
        returns (uint256 reward);
}
