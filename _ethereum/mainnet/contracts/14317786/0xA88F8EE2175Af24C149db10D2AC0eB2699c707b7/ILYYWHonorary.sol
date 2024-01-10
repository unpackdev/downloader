// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ILYYWHonorary is ERC721A, Ownable {
    using Strings for uint256;

    string public unrevealedURI;
    mapping(uint256 => string) public honoraryURIs;

    constructor(string memory _unrevealedURI) ERC721A("Honorary Weirdos", "ILYYWH") {
        unrevealedURI = _unrevealedURI;
    }

    function honoraryMint(uint256 _numberOfMints) public onlyOwner {
        _safeMint(msg.sender, _numberOfMints);
    }

    function revealToken(uint256 _tokenId, string memory _uri) external onlyOwner {
        honoraryURIs[_tokenId] = _uri;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
        require(_exists(_id), "ERC721: URI query for nonexistent token.");

        string memory uri = honoraryURIs[_id];

        return bytes(uri).length > 0
            ? uri
            : unrevealedURI;
    }
}
