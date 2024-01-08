// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: Squeebo                     *
 ****************************************
 *              Get Shwifty             *
 ****************************************/

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SkyDrip is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public TOTAL_SUPPLY = 72;
    bool public isActive        = false;
    uint public price           = 0.25 ether;

    string private _baseTokenURI = '';
    string private _tokenURISuffix = '';

    constructor()
      ERC721("SkyDrip NFTs", "SD"){
    }

    //public
    function mint(uint256 quantity) public payable {
        uint256 balance = totalSupply();
        require( isActive,                           "Sale is locked"           );
        require( balance + quantity <= TOTAL_SUPPLY, "Exceeds supply"           );
        require( msg.value >= price * quantity,      "Ether sent is not correct" );

        for( uint256 i; i < quantity; ++i ){
            _safeMint( msg.sender, balance + i );
        }
    }

    //onlyOwner
    function gift(uint256 quantity, address recipient) public onlyOwner {
        uint256 balance = totalSupply();
        require( balance + quantity <= TOTAL_SUPPLY, "Exceeds supply" );

        for(uint256 i; i < quantity; ++i ){
            _safeMint( recipient, balance + i );
        }
    }

    function setActive(bool isActive_) public onlyOwner {
        isActive = isActive_;
    }

    function setMaxSupply(uint maxSupply) public onlyOwner {
        require(maxSupply > totalSupply(), "Specified supply is lower than current balance" );
        TOTAL_SUPPLY = maxSupply;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance >= 0, "No funds available");
        Address.sendValue(payable(owner()), address(this).balance);
    }

    //metadata
    function setBaseURI(string memory baseURI, string memory suffix) public onlyOwner {
        _baseTokenURI = baseURI;
        _tokenURISuffix = suffix;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
    }

    //external
    fallback() external payable {}

    receive() external payable {}
}

