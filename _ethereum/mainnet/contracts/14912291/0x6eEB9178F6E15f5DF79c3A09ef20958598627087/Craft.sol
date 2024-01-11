// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

/// @custom:security-contact cagataycali@icloud.com
contract Craft is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private price = 0.001 ether;

    function contractURI() public pure returns (string memory) {
        return "https://craft.ropy.io/metadata.json";
    }

    constructor() ERC721("Craft", "CRAFT") {}

    function mint(string memory tokenURI) public payable {
        require(msg.value >= price, "Insufficent funds");
        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
    }

    function mintExternal(string memory tokenURI) external payable {
        require(msg.value >= price, "Insufficent funds");
        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function withdraw(address payable to) public onlyOwner {
        to.transfer(address(this).balance);
    }
}
