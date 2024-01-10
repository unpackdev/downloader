//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 @title DooDooLand for SharkDooDoo to live
 */
contract DooDooLand is ERC721Enumerable, Ownable {
    uint16 private constant MAX_SUPPLY = 500;

    string private _baseTokenURI;

    string private _contractURI;

    /// @dev Setup ERC721 and initial baseURI
    constructor(string memory initBaseURI, string memory contractUri)
        ERC721("DooDooLand", "DDL")
    {
        _baseTokenURI = initBaseURI;
        _contractURI = contractUri;
    }

    /// @dev Owner reserve
    function reserve(address to, uint256 amount) external onlyOwner {
        uint256 newTokenId = totalSupply();
        require(newTokenId + amount <= MAX_SUPPLY, "exceed max supply");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, newTokenId);
            newTokenId++;
        }
    }

    /// @dev Set baseURI
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /// @dev Contract URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev Override _baseURI
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
