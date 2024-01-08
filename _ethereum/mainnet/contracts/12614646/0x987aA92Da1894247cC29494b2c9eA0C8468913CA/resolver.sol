// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721CreatorCore.sol";
import "./Ownable.sol";

/**
 * resolver.addr
 */
contract resolver is Ownable {
    
    address private _creator;
    uint256 private _minted;

    constructor(address creator) {
        _creator = creator;
    }

    function setBaseTokenURI(string calldata uri, bool identical) external onlyOwner {
        IERC721CreatorCore(_creator).setBaseTokenURIExtension(uri, identical);
    }

    function setTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external onlyOwner {
        IERC721CreatorCore(_creator).setTokenURIExtension(tokenIds, uris);
    }    

    function setTokenURIPrefix(string calldata prefix) external onlyOwner {
        IERC721CreatorCore(_creator).setTokenURIPrefixExtension(prefix);
    }

    function resolve(address[] calldata receivers, string[] calldata hashes) external onlyOwner {
        require(receivers.length == hashes.length, "Invalid input");
        require(_minted+receivers.length <= 100, "Only 100 available");
        for (uint i = 0; i < receivers.length; i++) {
            IERC721CreatorCore(_creator).mintExtension(receivers[i], hashes[i]);
        }
        _minted += receivers.length;
    }
}
