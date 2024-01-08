// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract LegitimateNFT is ERC721, ERC721Enumerable, Ownable {
    constructor() ERC721("LegitimateNFT", "LGT") {}
    mapping(uint256 => address) public tokenRoyalties;

    // URI FUNCTIONS
    string baseURI = "https://lgt-server-prod.herokuapp.com/nft_metadata/";

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    // MINTING FUNCTIONS
    function mint(uint256 tokenId) public onlyOwner {
        _safeMint(msg.sender, tokenId);
    }

    function mint(uint256 tokenId, address to) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function mint(uint256 tokenId, address to, address royaltyOwner) public onlyOwner {
        _safeMint(to, tokenId);
        tokenRoyalties[tokenId] = royaltyOwner;
    }

    // Token Royalties
    function setTokenRoyalties(uint256 tokenId, address royaltyAddress) public onlyOwner {
        tokenRoyalties[tokenId] = royaltyAddress;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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