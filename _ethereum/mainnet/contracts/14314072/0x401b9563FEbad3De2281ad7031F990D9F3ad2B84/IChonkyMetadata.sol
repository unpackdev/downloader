// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChonkyMetadata {
    function buildTokenURI(
        uint256 id,
        uint256 genomeId,
        uint256 genome,
        string memory CID,
        address chonkySet,
        address chonkyAttributes
    ) external pure returns (string memory);
}
