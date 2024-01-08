// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./BaseOpenSea.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract ComplexGlass is ERC721, Ownable, BaseOpenSea, ERC721Enumerable, ERC721URIStorage {
    constructor(address proxyRegistryAddress) ERC721("Complex Glass", "GLASS") {

        _setOpenSeaRegistry(proxyRegistryAddress);
    } 
    
    /**
     * @dev Mint a new token with the specified ID and owner.  Also sets tokenURI
     */
    function mint(address to, uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Set the metadata URI for a token.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Get metadata URI
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }
    

    /**
     * @dev isApprovedForAll with gassless trading on OpenSea
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool)
    {
        // allows gas less trading on OpenSea
        return super.isApprovedForAll(owner, operator) || isOwnersOpenSeaProxy(owner, operator);
    }

    /**
     * @dev Set the metadata URI for a contract.
     */
    function setContractURI(string memory _contractURI) public onlyOwner {
        _setContractURI(_contractURI);
    }


    /* Necessary overrides below. No added functionality. */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}