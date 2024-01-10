//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GroupedURIs {
    event TokenToGroup(uint256 tokenId, uint256 groupId);

    /// @notice current group of tokenIds
    uint256 public currentGroupId;

    /// @notice the NFTs will first have centralized tokenURIs until the artist provide all files
    mapping(uint256 => string) public groupBaseURI;

    /// @notice mapping tokenId to group
    mapping(uint256 => uint256) public tokenGroup;

    function _incrementGroup(
        string memory previousGroupBaseURI,
        string memory newGroupBaseURI
    ) internal {
        if (bytes(previousGroupBaseURI).length != 0) {
            _setGroupURI(currentGroupId, previousGroupBaseURI);
        }
        _setGroupURI(++currentGroupId, newGroupBaseURI);
    }

    function _setGroupURI(uint256 group, string memory baseURI) internal {
        groupBaseURI[group] = baseURI;
    }

    function _setTokenGroup(uint256 tokenId, uint256 groupId) internal {
        tokenGroup[tokenId] = groupId;
        emit TokenToGroup(tokenId, groupId);
    }
}
