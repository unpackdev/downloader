//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "./Strings.sol";

/**
 * @notice EIP-721 reveal logic
 */
abstract contract Reveal is ERC721 {
    struct RevealGroup {
        uint64 startIndex;
        uint64 lastIndex;
    }
    /* state */
    uint[] private groupHashes;
    RevealGroup[] public revealGroups;
    string public unrevealedBaseUri = "";

    constructor() {}

    function revealHash(uint _tokenIndex) public view returns (uint) {
        for (uint _groupIndex = 0; _groupIndex < revealGroups.length; _groupIndex++) {
            RevealGroup memory _revealGroup = revealGroups[_groupIndex];
            if (_tokenIndex > _revealGroup.startIndex && _tokenIndex < _revealGroup.lastIndex) {
                return groupHashes[_groupIndex];
            }
        }
        return 0;
    }

    /**
     * @dev IERC721Metadata Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint _tokenId) external virtual override(IERC721Metadata) view returns (string memory) {
        require(exists(_tokenId), "erc721: nonexistent token");
        uint _groupHash = revealHash(_tokenId);
        if (_groupHash > 0) {
            return string(abi.encodePacked(
                _groupURI(_groupHash),
                Strings.toString(_tokenId),
                ".json"
            ));
        }
        return string(abi.encodePacked(
            unrevealedBaseUri,
            Strings.toString(_tokenId),
            ".json"
        ));
    }

    function _groupURI(uint _groupId) internal pure returns (string memory) {
        string memory _uri = "ipfs://f01701220";
        bytes32 value = bytes32(_groupId);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            bytes1 ix1 = value[i] >> 4;
            str[i*2] = alphabet[uint8(ix1)];
            bytes1 ix2 = value[i] & 0x0f;
            str[1+i*2] = alphabet[uint8(ix2)];
        }
        return string(abi.encodePacked(_uri, string(str), "/"));
    }

    function setRevealHash(uint _groupIndex, uint _revealHash) external onlyOwner {
        groupHashes[_groupIndex] = _revealHash;
    }

    function setUnrevealedBaseUri(string memory _unrevealedBaseUri) external onlyOwner {
        unrevealedBaseUri = _unrevealedBaseUri;
    }

    function reveal(uint16 _tokensCount, uint _revealHash) external onlyOwner {
        uint _groupIndex = revealGroups.length;
        RevealGroup memory _prev;
        if (_groupIndex > 0) {
            _prev = revealGroups[_groupIndex - 1];
        } else {
            _prev = RevealGroup({
                startIndex: 0,
                lastIndex: 1
            });
        }
        revealGroups.push(RevealGroup({
            startIndex: _prev.lastIndex - 1,
            lastIndex: _prev.lastIndex + _tokensCount
        }));
        groupHashes.push(_revealHash);
    }

    function undoReveal() external onlyOwner() {
        revealGroups.pop();
        groupHashes.pop();
    }
}
