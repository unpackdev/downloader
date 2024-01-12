// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract MojorInviteCard is ERC721, ERC721URIStorage,Ownable {

    uint public tokenId=0;

    constructor() ERC721("Mojor Invite Card", "Mojor Invite Card") {
    }

    function safeMint(address to,string memory uri)
    onlyOwner
    public
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        tokenId++;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }


    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


}