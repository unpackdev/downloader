// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Rockbunn is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 200; // Giveaway Campaign
    uint256 private _price = 0.05 ether;
    bool public _paused = true;

    // withdraw addresses
    address t1 = 0x4D48B015da844B2a8a86ac4e8DeDBBee5780E314; // 
    address t2 = 0xDeB34F38Ba2d81685a3744c6a728EAF5C8bd07dE; // 
    address t3 = 0x37c11B5fFFF83e4Be790F23C3Ebf0770e57cD235; // 
    address t4 = 0x5b137804dfa92CEd576595b73C3cB1F4258747d3; // Community Manager
    address t5 = 0x5D0dA5327511B22adfc5A7F8a4EAA088d42a2f3f; // Team
    address t6 = 0x6f79A69bCACc1aE2f3F767FD5b7dEd79e1AaC7D8; // Team
    address t7 = 0x26F9e69dE5964dA666715846639Da150fecbb6bb; // Team

    // 0-9999 rockbunn in total, First 10 generate bot is fix graphic that come from Collab Artist, From number 10 is randomly generate
    constructor(string memory baseURI) ERC721("Rockbunn", "RBN")  {
        setBaseURI(baseURI);

        // First 10 reserve for Callab Artist Mint
        _safeMint( t4, 0);
        _safeMint( t4, 1);
        _safeMint( t4, 2);
        _safeMint( t4, 3);
        _safeMint( t4, 4);
        _safeMint( t4, 5);
        _safeMint( t4, 6);
        _safeMint( t4, 7);
        _safeMint( t4, 8);
        _safeMint( t4, 9);
        // Next 5 reserve for Team Mint
        _safeMint( t1, 10);
        _safeMint( t2, 11);
        _safeMint( t5, 12);
        _safeMint( t6, 13);
        _safeMint( t7, 14);
    }

    function getRemainRockbunn() public view returns(uint256) {
        uint256 supply = totalSupply();
        return 10000 - supply - _reserved;
    } 


    function adopt(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 21,                              "You can adopt a maximum of 20 Rockbunn" );
        require( supply + num < 10000 - _reserved,      "Exceeds maximum Rockbunn supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved Rockbunn" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 5;
        require(payable(t1).send(_each*2));
        require(payable(t2).send(_each));
        require(payable(t3).send(_each));
        require(payable(t4).send(address(this).balance));
    }
}