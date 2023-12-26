// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

import "./IRenderer.sol";
import "./Mirrored721.sol";

contract ChecksPFP is Mirrored721, Ownable {

    address public renderer;

    constructor() Mirrored721(0x036721e5A769Cc48B3189EFbb9ccE4471E8A48B1, "Checks PFP", "CHECKSPFP") {}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return IRenderer(renderer).tokenURI(tokenId, _ownerOf(tokenId));
    }

    function svg(uint256 tokenId) public view returns (string memory) {
        return IRenderer(renderer).svg(tokenId);
    }

    function setRenderer(address _renderer) public onlyOwner {
        renderer = _renderer;
    }

}
