// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract EarlyBroadcasterComics is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 777;
    uint256 public TOKEN_PRICE = 111000000000000000; //0.1 ETH
    uint256 public SALE_STAGE = 1;
    bool public saleStarted = false;
    string public baseURI = "https://metaebc.bcsnft.io/";

    constructor() ERC721("EarlyBroadcasterComics", "EBC") {
        //
    }

    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), tokenId.toString()));
    }

    function mint() public payable {
        require(saleStarted == true, "Sale has not started.");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeds MAX_SUPPLY");
        require(totalSupply() + 1 <= SALE_STAGE * 111, "Exceeds stage MAX_SUPPLY");
        require(msg.value == TOKEN_PRICE, "Ether value sent is below the price");

        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }

    //OnlyOwner

    function setSaleStage(uint256 stage) public onlyOwner{
        SALE_STAGE = stage;
    }

    function startSale() public onlyOwner{
        saleStarted = true;
    }

    function pauseSale() public onlyOwner{
        saleStarted = false;
    }

    function tokenPrice(uint256 price) public onlyOwner{
        TOKEN_PRICE = price;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}