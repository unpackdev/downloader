// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Context.sol";

/**
 * @dev {ERC721} NFT contract:
 *
 *  - Constructed with base token URI pointing to metadata directory on IPFS.
 *  - Allows the NFT contract owner to update base token URI to outlive IPFS.
 *  - Allows the NFT contract owner to mint multiple tokens at a time.
 *  - Limits the total number of tokens minted to 100.
 *
 */
contract ElectricLegends is Context, Ownable, ERC721Enumerable {
    uint public constant MAX_SUPPLY = 100;
    string private _baseTokenURI;

    constructor() ERC721("Electric Legends", "ELL") {
        _baseTokenURI =
            "https://ipfs.io/ipfs/QmboRvzRNesPUGmAmd57wGoUkBFhLLz1Ygi5oh55rY7QDH/";
    }

    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(address to) public virtual onlyOwner {
        uint supply = totalSupply();
        require(supply < MAX_SUPPLY,
            "ElectricLegends: reached max token supply");
        _mint(to, supply);
    }

    function mintMultiple(address to, uint count) public virtual onlyOwner {
        uint supply = totalSupply();
        uint finalSupply = supply + count;
        require(finalSupply <= MAX_SUPPLY,
            "ElectricLegends: insufficient max token supply");
        for (uint tokenId = supply; tokenId < finalSupply; tokenId++) {
            _mint(to, tokenId);
        } 
    }

    function _beforeTokenTransfer(address from, address to, uint tokenId)
        internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
