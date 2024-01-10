// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract CatCat is ERC721A, Ownable {
    uint256 public MAX_PER_TX = 10;
    uint256 public MAX_SUPPLY = 1000;
    uint256 public FREE_MINTS = 300;
    uint256 public mintPrice = 0.01 ether;

    string public baseURI = "https://catcatmeow.net/metadata/";

    constructor() ERC721A("CatCatMeow", "CCM") {}

    function mint(uint256 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity <= MAX_PER_TX, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        if (totalSupply() + quantity > FREE_MINTS)
        {
            require(msg.value >= (mintPrice * quantity), "Not enough ether sent");
        }
        _safeMint(msg.sender, quantity);
    }

    function reserveMint(uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(msg.sender, quantity);
    }

    function setNumFreeMints(uint256 _numfreemints) external onlyOwner
    {
        FREE_MINTS = _numfreemints;
    }

    function setBaseURI(string memory _newbaseURI) external onlyOwner {
        baseURI = _newbaseURI;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}