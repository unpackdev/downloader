// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NFTTEST is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint8 private _maxMint;

    constructor() ERC721("NFT Test", "NFTTEST") {
        _maxMint = 10;
    }

    function setMaxMint(uint8 newMax) external onlyOwner {
        _maxMint = newMax;
    }

    function mint(uint count) external{
        require(count > 0 && count <= _maxMint, "Limit exceeded");
        for(uint8 i = 0; i< count; i++){
            _mint();
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return baseURI;
    }

    function burn(uint256[] calldata tokenIds) external {
        for(uint256 i = 0; i < tokenIds.length; i++){
            burn(tokenIds[i]);
        }
    }

    function burn(uint256 tokenId) private {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }

    function _mint() private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmTiW41B81nnC8WsitvBJqfKeDHxUkTaM5MohUmEVpHvye";
    }

}