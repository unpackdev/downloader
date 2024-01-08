// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MetaMobStandard is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    // Shared Metadata URI
    string _URI = "QmSbPFBmgpvkuBrpkYy6QFqJDTca4dMCJ8byni6ss3QEZ1";
    
    // Maximum supply of the NFT
    uint256 public constant maxSupply = 1000;

    constructor() ERC721("MetaMob OG Launch Pass: Standard", "MMLP") {}

    function safeMint(address to) public {
        require(totalSupply() < maxSupply, "MetaMob Standard Launch Pass are sold out");
        require(balanceOf(to) < 5, "You are only allowed 5 MetaMob Standard Launch Passes");
        
        uint256 passID = totalSupply() + 1;
        _safeMint(to, passID);
        _setTokenURI(passID, _URI);
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