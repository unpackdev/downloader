pragma solidity 0.5.17;

import "./ERC721Metadata.sol";
import "./Ownable.sol";


contract NFT is ERC721Metadata, Ownable {
    constructor(string memory name, string memory symbol)
        public
        ERC721Metadata(name, symbol)
    {}

    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
