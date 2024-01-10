// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./console.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract IdolCustom is ERC721Enumerable, Ownable {

    // Mapping from token ID to tokenURI
    mapping(uint256 => string) private _customTokenURIs;

    constructor() ERC721("Custom Idols", "cIDOLS"){}

    function mint(string calldata _tokenURI, uint256 _tokenId) public onlyOwner {
        _safeMint(owner(), _tokenId);
        _customTokenURIs[_tokenId] = _tokenURI;
    } 

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _customTokenURIs[tokenId];
    }

}
