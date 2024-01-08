// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract CutePuppies is ERC721, Ownable {

    uint256 public tokenCounter;
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("Cute Puppies", "PUPPY") {
        tokenCounter = 0;
    }

    function createCollectible(string memory _tokenURI) external onlyOwner returns (uint256) {
        uint256 newItemId = tokenCounter;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        tokenCounter = tokenCounter + 1;

        return newItemId;
    }

    function updateCollectible(uint _tokenId, string memory _tokenURI) external onlyOwner returns (bool) {
        _setTokenURI(_tokenId, _tokenURI);

        return true;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return  _tokenURIs[tokenId];
    }
}
