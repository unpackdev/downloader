pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

interface IBrandCentralClaimAuction {
    function tokenIdToLowerTicker(uint256 _tokenId) external view returns (string memory);
    function lowerTickerToTokenId(string calldata _lowerTicker) external view returns (uint256);
    function isRestrictedBrandTicker(string calldata _lowerTicker) external view returns (bool);
}
