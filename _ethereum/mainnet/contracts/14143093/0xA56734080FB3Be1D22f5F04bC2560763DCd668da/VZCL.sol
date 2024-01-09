// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";

contract VZCL is ERC721, Ownable {
    using Address for address;

    // ===== Variables =====
    string public baseTokenURI;
    uint256 public collectionSize = 20;
    uint256 public totalSupply = 0;

    // ===== Constructor =====
    constructor() ERC721("Verizon x Chibi Labs: Token of Love", "VZCL") {}

    // ===== Owner mint =====
    function mint(address to, uint256 amount) external onlyOwner {
        require(
            (totalSupply + amount) <= collectionSize,
            "Over collection limit"
        );
        for (uint256 i = 0; i < amount; i++) {
            totalSupply += 1;
            _mint(to, totalSupply);
        }
    }

    // ===== Setter =====
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // ===== View =====
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }
}
