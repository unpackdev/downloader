// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract Lemonhead is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public maxSupply = 8000;
    uint256 public price = 0.02 ether;

    string private _baseTokenURI;

    constructor(address owner) ERC721("Lemonhead", "LHEAD") {
        transferOwnership(owner);

        for (uint256 i = 0; i < 16; i++) {
            _safeMint(owner, i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMaxSupply(uint256 num) public onlyOwner {
        require(num < maxSupply); // supply cannot be increased
        require(num >= totalSupply()); // supply cannot be lower than what is already minted
        maxSupply = num;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();

        require(num > 0 && num <= 8, "too many");
        require(supply.add(num) <= maxSupply, "not enough supply");
        require(msg.value >= price.mul(num), "not enough ether");

        for (uint256 i = 0; i < num; i++) {
            _safeMint(msg.sender, supply.add(i));
        }
    }
}