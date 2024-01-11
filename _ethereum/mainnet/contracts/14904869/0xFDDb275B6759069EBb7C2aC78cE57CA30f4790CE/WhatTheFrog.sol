// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract WhatTheFrog is ERC721A, Ownable {
    
    uint256 public MAX_SUPPLY = 2000;
    uint256 public MAX_FREE_SUPPLY = 500;

    uint256 public MINT_PRICE = 0.005 ether;

    uint256 public MAX_MINT_PER_TX = 20;

    uint256 public MAX_FREE_MINT_PER_WALLET = 1;

    bool public mintStarted = true;

    using Strings for uint256;
    string public baseURI;
    mapping(address => uint256) private _mintedFreeAmount;

    constructor(string memory initBaseURI) ERC721A("WhatTheForg", "WTF") {
        baseURI = initBaseURI;
    }

    function mint(uint256 count) external payable {
        uint256 cost = MINT_PRICE;
        bool isFree = ((totalSupply() + count < MAX_FREE_SUPPLY + 1) &&
            (_mintedFreeAmount[msg.sender] + count <=
                MAX_FREE_MINT_PER_WALLET)) || (msg.sender == owner());

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < MAX_SUPPLY + 1, "Sold out!");
        require(mintStarted, "Minting is not live yet.");
        require(count < MAX_MINT_PER_TX + 1, "Max per TX reached.");

        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        MAX_FREE_SUPPLY = amount;
    }

    function saleStateToggle() external onlyOwner {
        mintStarted = !mintStarted;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        MINT_PRICE = _newPrice;
    }

    function teamMint(uint256 _number) external onlyOwner {
        _safeMint(_msgSender(), _number);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
