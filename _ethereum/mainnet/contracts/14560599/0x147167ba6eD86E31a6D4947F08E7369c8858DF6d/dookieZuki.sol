/*
/$$$$$$$                      /$$       /$$           /$$$$$$$$           /$$       /$$
| $$__  $$                    | $$      |__/          |_____ $$           | $$      |__/
| $$  \ $$  /$$$$$$   /$$$$$$ | $$   /$$ /$$  /$$$$$$      /$$/  /$$   /$$| $$   /$$ /$$
| $$  | $$ /$$__  $$ /$$__  $$| $$  /$$/| $$ /$$__  $$    /$$/  | $$  | $$| $$  /$$/| $$
| $$  | $$| $$  \ $$| $$  \ $$| $$$$$$/ | $$| $$$$$$$$   /$$/   | $$  | $$| $$$$$$/ | $$
| $$  | $$| $$  | $$| $$  | $$| $$_  $$ | $$| $$_____/  /$$/    | $$  | $$| $$_  $$ | $$
| $$$$$$$/|  $$$$$$/|  $$$$$$/| $$ \  $$| $$|  $$$$$$$ /$$$$$$$$|  $$$$$$/| $$ \  $$| $$
|_______/  \______/  \______/ |__/  \__/|__/ \_______/|________/ \______/ |__/  \__/|__/
*/

// SPDX-License-Identifier: MIT
//GAS OPTIMIZED!
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract DookieZukis is ERC721Enumerable, Ownable {


    string _baseTokenURI;
    string _notRevealedURI;
    uint256 public maxDookies;
    uint256 public nftPerAddressLimit;
    uint256 private dookiePrice = 0.01 ether;
    bool public saleIsActive = false;
    bool public revealed = false;


    constructor() ERC721("DookieZukis", "DZ")  {
        maxDookies = 2222;
    }


    function mintDookie(uint256 dookieQuantity) public payable {
        uint256 supply = totalSupply();
        require( saleIsActive,"Sale is paused" );

        if (msg.sender != owner()) {
            require(msg.value >= dookiePrice * dookieQuantity, "TX Value not correct");
        }
        require( supply + dookieQuantity <= maxDookies, "Exceeds maximum supply" );
        require( msg.value >= dookiePrice * dookieQuantity,"TX Value not correct" );

        for(uint256 i; i < dookieQuantity; i++){
            _safeMint( msg.sender, supply + i );
        }
    }


    function setPrice(uint256 newDookiePrice) public onlyOwner() {
        dookiePrice = newDookiePrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if(revealed == false) {
            return _notRevealedURI;
        }

        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }



    function setNotRevealedURI(string memory notRevealedURI) public onlyOwner {
      _notRevealedURI = notRevealedURI;
    }


    function reveal() public onlyOwner {
        revealed = true;
    }



 function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }


    function withdraw_all() public onlyOwner{
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

}