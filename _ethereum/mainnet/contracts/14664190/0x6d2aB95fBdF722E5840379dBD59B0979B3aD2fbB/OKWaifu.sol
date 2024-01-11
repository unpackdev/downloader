// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721A.sol";

contract OKWaifu is ERC721A, Ownable {
    string public baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 5;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 constant PRICE = 0.01 * 10**18; // 0.01 ETH

    event Minted(address minter, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI) ERC721A("OK Waifu", "OKW") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(tx.origin == msg.sender, "OKW: ERR_ORIGIN_NOT_ALLOWED");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "OKW: ERR_MAX_MINT_PER_ADDR"
        );
        require(totalSupply() + quantity <= MAX_SUPPLY, "OKW: ERR_MAX_SUPPLY");
        require(PRICE * quantity <= msg.value, "OKW: ERR_INSUFFICIENT_FUNDS");

        _safeMint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "OKW: ERR_OVER");
    }
}
