// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MonkeyRepublic is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public MAX_MINTS = 10;
    uint256 public MAX_SUPPLY = 4000;
    uint256 public mintRate = 0.01 ether;
    uint256 public freeMints = 1000;
    bool public saleIsActive = false;

    string public baseURI = "ipfs://QmUoLDRjFe1Nda16TwttmftSLg41zpfVBTY58zChc5KfB9/";

    constructor() ERC721A("Monkey Republic", "MRP") {}

    function mint(uint256 quantity) external payable {
        require(saleIsActive, "Sale not active yet");
        require(quantity <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        if(totalSupply() + quantity > freeMints){
            require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        }

        _safeMint(msg.sender, quantity);
    }

    function toggleSaleState() external onlyOwner{
        saleIsActive = !saleIsActive;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        // It's because tokenId starts with 0 but metadatas starts with 1.
        tokenId = tokenId + 1;
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),".json")) : "";
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
