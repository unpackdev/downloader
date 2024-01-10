// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract DoodledMfers is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 6500; // Total amount of mfers
    uint256 public constant PRICE = 0.012 ether; // Price
    uint256 public constant MAX_PER_WALLET = 50; // Max mint amount per address
    uint256 public constant MAX_FREE_SUPPLY = 500; // Max amount of free mfers

    // URI
    string public baseURI = "ipfs://QmRj3zjq9Bk4bgnFguaT4M47VtJWKHmj1Y11rJPRfF2CfJ/";

    constructor() ERC721A("Doodled Mfers", "DM") {}

    function getPrice(uint256 _supply) internal pure returns (uint256 _price) {
        if (_supply < MAX_FREE_SUPPLY) {
            return 0 ether;
        } else {
            return PRICE;
        }
    }

    function mint(uint256 quantity) external payable {
        require(quantity <= MAX_PER_WALLET, "REACH_MAX_MINT");
        require(quantity > 0, "QUANTITY_ZERO");
        require(totalSupply() + quantity <= MAX_SUPPLY, "SOLD_OUT");
        require(msg.value >= getPrice(totalSupply()) * quantity, "INSUFFICIENT_ETH");

        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory){
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // Owner functions

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
