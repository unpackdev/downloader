// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISubjectWithGeneChanger {
    function genomeChanges(uint256 tokenId)
        external
        view
        returns (uint256 genomeChanges);
}
