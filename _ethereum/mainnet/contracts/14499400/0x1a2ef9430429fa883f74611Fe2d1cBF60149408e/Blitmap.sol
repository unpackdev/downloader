// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
import "./BytesLib.sol";
import "./IBlitmap.sol";

contract Blitmap is IBlitmap {
    bytes _tokenData;
    bytes _creators;
    string[100] _names;

    constructor(bytes memory tokenData, bytes memory creators) {
        _tokenData = tokenData;
        _creators = creators;
    }

    function setNames(string[100] memory names) public {
        _names = names;
    }

    function tokenDataOf(uint256 tokenId) public view returns (bytes memory) {
        return BytesLib.slice(_tokenData, tokenId * 12, 12);
    }

    function tokenCreatorOf(uint256 tokenId) public view returns (address) {
        return BytesLib.toAddress(_creators, tokenId * 20);
    }

    function tokenNameOf(uint256 tokenId) public view returns (string memory) {
        return _names[tokenId];
    }
}
