//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC2981.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract NFT is ERC721Enumerable, Ownable {
    mapping(uint256 => string) tokenUris;

    constructor() ERC721("NFT", "NFT") {}

    function mint(uint256 tokenId, string memory uri) external onlyOwner {
        require(!_exists(tokenId), "token already exists");
        tokenUris[tokenId] = uri;
        _safeMint(msg.sender, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "token does not exist");
        return tokenUris[tokenId];
    }
}
