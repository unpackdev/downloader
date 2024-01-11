// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MonkeyRepublic is ERC721A, Ownable {
    uint256 public MAX_MINTS = 20;
    uint256 public MAX_SUPPLY = 5000;
    uint256 public mintRate = 0.01 ether;
    uint256 public freeMints = 1000;

    string public baseURI = "ipfs://QmUoLDRjFe1Nda16TwttmftSLg41zpfVBTY58zChc5KfB9/";

    constructor() ERC721A("Monkey Republic", "MRP") {}

    function mint(uint256 quantity) external payable {
        require(quantity <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        if(totalSupply() + quantity > freeMints){
            require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        }

        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }
}
