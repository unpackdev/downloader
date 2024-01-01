//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice BitRotRenderer interface as it pertains to BitRotGenerative
 */
interface IBitRotRenderer {
    function tokenURI(
        bytes32 blockHash,
        uint256 tokenId,
        uint256 timestamp,
        address storageContract,
        string memory previewsBaseUri
    ) external view returns (string memory);
}
