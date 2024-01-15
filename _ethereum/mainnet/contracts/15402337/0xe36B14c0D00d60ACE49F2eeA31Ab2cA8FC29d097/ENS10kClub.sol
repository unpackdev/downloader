// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ENS10kClub is ERC721A, Ownable {
    uint256 private _collectionSize = 10000;
    string private _baseTokenURI =
        "ipfs://bafybeidult4o5cgyvfq6hqm55hiwp3whlrrkwdiatmu5mfsrknozurxjyq/";

    constructor() ERC721A("10kClub", "ens") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(address to, uint256 quantity) public onlyOwner {
        require(
            totalSupply() + quantity <= _collectionSize,
            "Reached max supply."
        );
        _safeMint(to, quantity);
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}