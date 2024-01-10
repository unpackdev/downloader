//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract ParlerDaoNft is ERC721Enumerable, Ownable {
    uint256 public MAX_PUBLIC_SUPPLY = 950;

    string public baseUri = "https://gateway.pinata.cloud/ipfs/QmanxZGuzCHZ8Zr18L87v95hpqvLDDrnZsgTqGGdBATr4d/";

    constructor() ERC721("Parler DAO Pineapples", "PARLERDAO") {
    }

    function mint() public payable {
        require(totalSupply() < MAX_PUBLIC_SUPPLY, "Mint complete");
        require(msg.value == getPrice(), "Invalid payment amount");
        _mint(msg.sender, totalSupply() + 1);
    }

    function creatorMint() public onlyOwner {
        require(totalSupply() >= MAX_PUBLIC_SUPPLY, "Public sale isn't over");
        for (uint i = 0; i < 50; i++) {
            _mint(msg.sender, totalSupply() + 1);
        }
    }

    function getPrice() public view returns (uint256) {
        return (totalSupply() / 100 + 1) * 0.069 ether;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}