// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract DeFineBlindNFT is ERC721Enumerable, ERC721URIStorage, Ownable {
    string public baseUri;
    mapping (address => bool) whitelisted;
    event Mint(address indexed minter, uint256 indexed tokenId);
    
    constructor() ERC721("DeFine Blind NFT", "DBN") {}

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        super._setTokenURI(tokenId, _tokenURI);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
    
    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }
    
    function mint(address minter) external returns (uint256) {
        require(whitelisted[msg.sender] == true, 'invalid call');
        uint256 tokenIndex = totalSupply() + 1;
        _safeMint(minter, tokenIndex);
        emit Mint(minter, tokenIndex);
        return tokenIndex;
    }
    
    function whitelist(address _address) external onlyOwner {
        whitelisted[_address] = true;
    }
    
    function blacklist(address _address) external onlyOwner {
        whitelisted[_address] = false;
    }
        
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
}