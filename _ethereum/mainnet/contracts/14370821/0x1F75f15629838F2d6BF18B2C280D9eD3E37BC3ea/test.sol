// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract CosmiqToadzNFT is ERC721A, Ownable {
    uint256 MAX_MINTS = 3;
    uint256 MAX_SUPPLY = 420;

    bool public saleIsActive = false;

    string public baseURI = "https://cosmiqtoadz.xyz/assets/ct/metadata/";

    constructor() ERC721A("Cosmiq Toadz", "CSMQTDZ") {}

    function mint(uint256 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(saleIsActive, "Sale must be active to mint");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(msg.sender, quantity);
    }

    function reserveMint(uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(msg.sender, quantity);
    }

    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}