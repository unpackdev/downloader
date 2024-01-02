// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

error TokenDoesNotExist();

contract ConvictionSBT is ERC721, Ownable {
    using Strings for uint256;
    
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    constructor(address initialOwner)
        ERC721("Studio Mayflower", "STMF")
        Ownable(initialOwner)
    {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // =========================================================================
    //                                 SBT
    // =========================================================================

    function _update(
        address to, 
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address){
        require(msg.sender == owner(), "Err: token is SOUL BOUND");
        // Emergency transfer by owner
        if(_ownerOf(tokenId) != address(0)) {
            // give approval to owner
            super._approve(owner(), tokenId, _ownerOf(tokenId));
        }
        return super._update(to, tokenId, auth);
    }

    

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) revert TokenDoesNotExist();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

}