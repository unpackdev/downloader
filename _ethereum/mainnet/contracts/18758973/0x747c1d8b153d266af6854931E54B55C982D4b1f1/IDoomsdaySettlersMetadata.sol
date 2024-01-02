// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

interface IDoomsdaySettlersMetadata {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}