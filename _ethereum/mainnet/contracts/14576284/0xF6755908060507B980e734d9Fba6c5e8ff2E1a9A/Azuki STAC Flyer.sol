// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ASTACF is ERC721A, Ownable {
    constructor() ERC721A("Azuki STAC Flyer", "ASTACF") {
        _baseTokenURI = "https://stonedapeclub.mypinata.cloud/ipfs/QmXbxyJup8atmQobd6DWxwh79Syd1fyebMbpaG1Ai7bGiy";
    }
    string private _baseTokenURI;

    // Metadata
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721AMetadata: URI query for nonexistent token");
    return _baseTokenURI;
    }

    // Minting
    function mint(address[] memory to) public onlyOwner {
        for(uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], 1);
        }    
    }
}