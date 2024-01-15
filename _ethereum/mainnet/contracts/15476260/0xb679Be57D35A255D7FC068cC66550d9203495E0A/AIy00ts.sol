// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
                                             
contract aiy00ts is ERC721A, Ownable {

    bool public revealed = false;

    string public baseURI;
    string public unrevealedURI = "ipfs/Qmd6jFuZX7sfHry3wNx1BTPumdQPX8wZWfTXq6itUqAfKR";

    uint256 public maxSupply = 999;
    uint256 public maxMintAmount = 6;
    uint256 public cost = 0.0033 ether;

    constructor() ERC721A("ai y00ts", "AY00T") {}

    function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if(revealed == false) {
            return unrevealedURI;
        }
        else {
            string memory uri = _baseURI();
            return bytes(uri).length != 0 ? string(abi.encodePacked(uri, _toString(tokenId), ".json")) : '';
        }
    }

    function mint(uint256 _mintAmount) public payable {
        require(totalSupply() + _mintAmount <= maxSupply);
        require(_mintAmount <= maxMintAmount);
        require(msg.value >= _mintAmount * cost);

        _safeMint(msg.sender, _mintAmount);
    }

    function ownerMint(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply);

        _safeMint(_to, _amount);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
		baseURI = _newURI;
	}
}