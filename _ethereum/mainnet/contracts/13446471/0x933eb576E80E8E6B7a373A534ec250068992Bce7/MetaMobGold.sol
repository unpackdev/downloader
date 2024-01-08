// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MetaMobGold is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    // Shared Metadata URI
    string _URI = "QmWB5hyw2bFwgFBzv9NpbLhx1cnQxvz1ARS1jhef2PzkRd";
    
    // Maximum supply of the NFT
    uint256 public constant maxSupply = 100;
    
    // Price of NFT
    uint256 public constant price = 300000000000000000;

    constructor() ERC721("MetaMob OG Launch Pass: Gold", "MMOG") {}

    function safeMint(address to) public payable {
        require(totalSupply() < maxSupply, "MetaMob OG Launch Passes are sold out");
        require(msg.value >= price, "Price is 0.3 ether (300,000,000,000,000,000 wei)");
        require(balanceOf(to) < 3, "You are only allowed 3 MetaMob Gold Launch Passes");
        
        uint256 passID = totalSupply() + 1;
        _safeMint(to, passID);
        _setTokenURI(passID, _URI);
    }

    function withdrawFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}