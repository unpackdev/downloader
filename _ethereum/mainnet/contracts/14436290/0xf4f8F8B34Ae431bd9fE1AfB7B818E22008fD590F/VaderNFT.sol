// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract VaderNFT is ERC721, Ownable {
    using Strings for uint256;

    uint256 public maxSupply;
    uint256 public totalSupply;
    uint256 public price;
    string public baseURI;

    constructor(
        uint256 maxSupply_,
        uint256 price_,
        string memory baseURI_
    ) ERC721("inVADERs", "inVADERs") {
        maxSupply = maxSupply_;
        price = price_;
        baseURI = baseURI_;
    }

    function mint(
        uint256 quantity
    ) public payable {
        uint256 total = quantity * 2;
        require(totalSupply + total <= maxSupply, "Mint exceed max supply");
        require(price * quantity <= msg.value, "Value sent is not correct");

        for (uint256 i = 1; i <= total; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
        totalSupply += total;
    }

    function withdraw(
    ) public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setPrice(
        uint256 price_
    ) external onlyOwner {
        price = price_;
    }

    function setBaseURI(
        string calldata baseURI_
    ) external onlyOwner {
        baseURI = baseURI_;
    }

}
