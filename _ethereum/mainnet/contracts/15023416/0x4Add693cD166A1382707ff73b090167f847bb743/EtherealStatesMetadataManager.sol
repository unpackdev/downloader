// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./OwnableOperators.sol";

import "./Strings.sol";

contract EtherealStatesMetadataManager is OwnableOperators {
    struct GroupURI {
        uint256 upTo;
        string uri;
    }

    /// @notice group of tokens revealed
    mapping(uint256 => GroupURI) public groups;

    /// @notice for token ids with a very specific uri
    mapping(uint256 => string) public tokenURIs;

    /// @notice next group id
    uint256 public nextGroupId;

    /// @notice unrevealed uri
    string private _unrevealedURI;

    /// @notice concat unrevealed uri
    bool private _concatUnrevealed;

    function tokenURI(uint256 tokenId) public view returns (string memory uri) {
        uri = tokenURIs[tokenId];

        if (bytes(uri).length == 0) {
            // find token id group
            uri = groupForTokenId(tokenId).uri;
            if (bytes(uri).length != 0) {
                uri = string.concat(uri, Strings.toString(tokenId), '.json');
            } else {
                // no group? unrevealed
                if (_concatUnrevealed) {
                    uri = string.concat(
                        unrevealedURI(),
                        Strings.toString(tokenId),
                        '.json'
                    );
                } else {
                    uri = unrevealedURI();
                }
            }
        }
    }

    function unrevealedURI() public view returns (string memory uri) {
        uri = _unrevealedURI;
        if (bytes(uri).length == 0) {
            uri = 'ipfs://QmeDgTDx5Lhxt4x5ttmHgk8o7Lfr73DfbcRmtXqvadCMD7/';
        }
    }

    function groupForTokenId(uint256 tokenId)
        public
        view
        returns (GroupURI memory group)
    {
        uint256 lastGroupId = nextGroupId;
        for (uint256 i; i <= lastGroupId; i++) {
            group = groups[i];
            if (group.upTo >= tokenId) {
                break;
            }
        }
    }

    /////////////////////////////////////////////////////////
    // Gated Operator                                      //
    /////////////////////////////////////////////////////////

    /// @notice allows an operator to set the tokenURI for a token, for reasons
    /// @param tokenId the token id
    /// @param uri the uri
    function setTokenURI(uint256 tokenId, string calldata uri)
        external
        onlyOperator
    {
        tokenURIs[tokenId] = uri;
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice allows owner to set the next group data
    /// @param group the group data
    function nextGroup(GroupURI calldata group) external onlyOwner {
        setGroup(nextGroupId++, group);
    }

    /// @notice allows owner to set the group data for given groupId
    /// @param groupId the group id
    /// @param group the group data
    function setGroup(uint256 groupId, GroupURI calldata group)
        public
        onlyOwner
    {
        groups[groupId] = group;
    }

    /// @notice allows owner to set the unrevealed URI
    /// @param newUnrevealedURI the new unrevealed URI
    function setUnrevealedURI(string calldata newUnrevealedURI)
        public
        onlyOwner
    {
        _unrevealedURI = newUnrevealedURI;
    }

    /// @notice allows owner to change the way unrevealed are build
    /// @param newConcatUnrevealed the new concat unrevealed config
    function setConcatUnrevealed(bool newConcatUnrevealed) public onlyOwner {
        _concatUnrevealed = newConcatUnrevealed;
    }
}
