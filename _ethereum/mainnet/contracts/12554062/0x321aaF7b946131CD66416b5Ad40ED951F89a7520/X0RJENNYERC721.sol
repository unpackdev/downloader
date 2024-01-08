// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract X0RJENNYERC721 is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("x0rJenny", "X0RJENNY") {}

    /**
     * @notice Mint a single nft
     */
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    /**
     * @notice Set tokenURI for a specific tokenId
     * @param tokenId of nft to set tokenURI of
     * @param _tokenURI URI to set for the given tokenId (IPFS hash)
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner{
        _setTokenURI(tokenId, _tokenURI);
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
