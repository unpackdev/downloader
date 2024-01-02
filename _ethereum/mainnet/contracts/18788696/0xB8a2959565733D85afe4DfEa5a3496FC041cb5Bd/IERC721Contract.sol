// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IERC721Contract {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getOwnTokenIds(address _owner) external view returns (uint256[] memory);
    function emitLockState(uint256 _tokenId, bool _locked) external;
    function emitMetadataUpdated(uint256 _tokenId) external;
}