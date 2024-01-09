// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";

contract NFTForAll is ERC721 {

    uint256 public totalSupply;
    mapping(uint256 => string) internal tokenURIs;

    constructor() ERC721("NFTForAll", "NFT4All") {}

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenURIs[tokenId];
    }

    function mint(address _to, string calldata _metadata) external {
        totalSupply += 1;
        _mint(_to, totalSupply);
        tokenURIs[totalSupply] = _metadata;
    }
}
