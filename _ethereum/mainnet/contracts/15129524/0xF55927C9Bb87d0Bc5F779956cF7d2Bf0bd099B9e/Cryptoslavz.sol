// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Cryptoslavz is ERC721A, Ownable {
    bool public isLive = false;
    mapping(address => uint256) public walletMints;
    string public baseURI;

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    function mint(uint256 _amount) external {
        require(isLive, "Not live");
        require(_amount > 0, "Cannot mint 0");
        require(_amount <= 5, "Max 5 per transaction");
        require(walletMints[msg.sender] + _amount <= 5, "Max 5 per wallet");
        require(totalSupply() + _amount <= 5000, "Max supply of 5000 reached");
        walletMints[msg.sender] = walletMints[msg.sender] + _amount;
        _safeMint(msg.sender, _amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function toggleLive() external onlyOwner {
        isLive = !isLive;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
}
