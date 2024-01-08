// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract QverseNFT is ERC721, Ownable, ERC721Enumerable, ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    
    string _tokenBaseURI;
    
    Counters.Counter _tokenIdCounter;
    mapping(uint256 => bool) _upgradedTokens;
    mapping(uint256 => string) _tokenURIs;

    constructor() ERC721("QverseNFT", "QVRS") {
        _tokenIdCounter.increment();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    function upgrade(address to, uint256[] calldata tokenIds) public onlyRole(UPGRADER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            require(totalSupply() >= tokenId, "token does not exist");
            require(!_upgradedTokens[tokenId], "token already used in upgrade");
            require(ownerOf(tokenId) == to, "address is not owner of token");
            
            _upgradedTokens[tokenId] = true;
        }
        
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    function setBaseURI(string calldata baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenBaseURI = baseURI;
    }
    
    function setTokenURI(uint256 tokenId, string calldata newTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenURIs[tokenId] = newTokenURI;
    }
    
    function withdrawAll() public onlyRole(DEFAULT_ADMIN_ROLE) {
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
        bytes memory tokenURIBytes = bytes(_tokenURIs[tokenId]);
        if (tokenURIBytes.length > 0) {
            return _tokenURIs[tokenId];
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
