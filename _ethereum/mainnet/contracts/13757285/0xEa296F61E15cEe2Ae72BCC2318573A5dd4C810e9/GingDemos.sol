// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract GingDemos is ERC721Enumerable, Ownable {
    using Strings for uint256;

    address private constant _fd = 0xFd015f1C18D015d708b1C990f2e1Aa86986Bd2d6;

    // URI variables
    // ------------------------------------------------------------------------
    string private _contractURI;
    string private _baseTokenURI;

    // Events
    // ------------------------------------------------------------------------
    event BaseTokenURIChanged(string baseTokenURI);
    event ContractURIChanged(string contractURI);

    // Constructor
    // ------------------------------------------------------------------------
    constructor() ERC721("WayOfGingDemos", "GINGDEMOS") {}

    // Base URI Functions
    // ------------------------------------------------------------------------
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
        emit ContractURIChanged(URI);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setBaseTokenURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
        emit BaseTokenURIChanged(URI);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // Mint functions
    // ------------------------------------------------------------------------
    function createItem(address addr, uint256 quantity) external onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(addr, totalSupply() + 1);
        }
    }

    // Withdraw functions
    // This contract shouldn't technically ever hold tokens, but just in case...
    // ------------------------------------------------------------------------
    function withdrawBalance() external onlyOwner {
        payable(_fd).transfer(address(this).balance);
    }
}