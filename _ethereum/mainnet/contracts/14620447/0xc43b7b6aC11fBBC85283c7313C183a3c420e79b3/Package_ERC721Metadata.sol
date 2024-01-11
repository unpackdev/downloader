// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Package_ERC721.sol";
import "./ERC721Metadata.sol";
import "./utils.sol";

/**
 * @dev Implementation of ERC721Metadata
 */
contract Package_ERC721Metadata is Package_ERC721, ERC721Metadata {
    mapping(uint256 => string) private _tokenCid;
    mapping(uint256 => bool) private _overrideCid;

    string private _metadata;
    string private _contractName;
    string private _contractSymbol;
    string private _fallbackCid;

    bool private _isRevealed;
    bool private _setURI;
    bool private _jsonExtension;

    constructor(string memory name_, string memory symbol_, string memory fallbackCid_) {
        _contractName = name_;
        _contractSymbol = symbol_;
        _fallbackCid = fallbackCid_;
        _isRevealed = false;
        _setURI = false;
    }

    function name() public view override returns (string memory) {
        return _contractName;
    }

    function symbol() public view override returns (string memory) {
        return _contractSymbol;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (_tokenId == 0 || _tokenId > _currentTokenId()) {
            return "Token ID out of range";
        } else if (_overrideCid[_tokenId] == true) {
            return string(abi.encodePacked(_ipfs(), _tokenCid[_tokenId]));
        } else {
            if (_isRevealed == true) {
                return _revealURI(_tokenId);
            } else {
                return string(abi.encodePacked(_ipfs(), _fallbackCid));
            }
        }
    }

    function _revealURI(uint256 _tokenId) internal view returns (string memory) {
        if (_jsonExtension == true) {
            return string(abi.encodePacked(_ipfs(), _metadata, "/", utils.toString(_tokenId), ".json"));
        } else {
            return string(abi.encodePacked(_ipfs(), _metadata, "/", utils.toString(_tokenId)));
        }
    }

    function _ipfs() internal pure returns (string memory) {
        return "ipfs://";
    }

    function _overrideTokenURI(uint256 _tokenId, string memory _cid) internal {
        _tokenCid[_tokenId] = _cid;
        _overrideCid[_tokenId] = true;
    }

    function _setRevealURI(string memory _cid, bool _isExtension) internal {
        require(_isRevealed == false, "ERC721: reveal has already occured");
        _metadata = _cid;
        _jsonExtension = _isExtension;
        _setURI = true;
    }

    function _checkURI(uint256 _tokenId) internal view returns (string memory) {
        if (_tokenId == 0 || _tokenId > _currentTokenId()) {
            return "Token ID out of range";
        } else if (_revealed() == true) {
            return "Tokens have been revealed";
        } else {
            return _revealURI(_tokenId);
        }
    }

    function _reveal() internal {
        require(_setURI == true, "ERC721: reveal URI not set");

        _isRevealed = true;
    }

    function _revealed() internal view returns (bool) {
        return _isRevealed;
    }
}
