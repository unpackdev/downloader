// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract BubbleheadNinjas is ERC721, Ownable
{
    using Strings for string;

    uint public constant MAX_TOKENS = 10000;
    uint public constant NUMBER_RESERVED_TOKENS = 35;
    uint256 public constant PRICE = 80000000000000000; //0.08 eth in wei

    bool public saleIsActive = false;

    uint public reservedTokensMinted = 0;
    uint public supply = 0;
    string private _baseTokenURI;

    constructor() ERC721("AxoNinjas", "AXN") {}

    function mintToken(uint256 amount) external payable
    {
        require(saleIsActive, "Sale must be active to mint");
        require(supply < MAX_TOKENS, "Sold out!");
        require(amount > 0 && amount <= 10, "Max 10 NFTs");
        require(supply + 1 <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE, "Not enough ETH for transaction");

        _safeMint(msg.sender, supply);
        supply++;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function mintReservedTokens(uint256 amount) external onlyOwner
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        for (uint i = 0; i < amount; i++)
        {
            _safeMint(owner(), supply);
            supply++;
            reservedTokensMinted++;
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    ////
    //URI management part
    ////

    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}
