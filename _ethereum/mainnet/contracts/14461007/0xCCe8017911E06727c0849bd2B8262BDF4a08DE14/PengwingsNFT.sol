//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract PengwingsNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("PengwingsNFT", "NFT") {}

    function mintNFT(address recipient, string memory tokenURI, string memory tokenURI2, string memory tokenURI3)
        public payable
    {
        require(msg.value >= 0.01 ether, "Sorry, not enough ETH sent");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        bytes memory tokenURI2EmptyStringTest = bytes(tokenURI2); // Uses memory
        bytes memory tokenURI3EmptyStringTest = bytes(tokenURI3); // Uses memory
        if (tokenURI2EmptyStringTest.length != 0 && tokenURI3EmptyStringTest.length != 0) {
            require(msg.value >= 0.025 ether, "Sorry, not enough ETH sent");
            _tokenIds.increment();
            uint256 newItemId2 = _tokenIds.current();
            _mint(recipient, newItemId2);
            _setTokenURI(newItemId2, tokenURI2);
            _tokenIds.increment();
            uint256 newItemId3 = _tokenIds.current();
            _mint(recipient, newItemId3);
            _setTokenURI(newItemId3, tokenURI3);
        } 
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawAmount(uint amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}