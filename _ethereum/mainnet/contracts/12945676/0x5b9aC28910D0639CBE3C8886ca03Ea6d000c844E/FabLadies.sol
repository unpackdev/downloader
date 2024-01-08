// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// Built with
//────────█████─────────────█████
//────████████████───────████████████
//──████▓▓▓▓▓▓▓▓▓▓██───███▓▓▓▓▓▓▓▓▓████
//─███▓▓▓▓▓▓▓▓▓▓▓▓▓██─██▓▓▓▓▓▓▓▓▓▓▓▓▓███
//███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███
//██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
//██▓▓▓▓▓▓▓▓▓──────────────────▓▓▓▓▓▓▓▓██
//██▓▓▓▓▓▓▓─██───████─█──█─█████─▓▓▓▓▓▓██
//██▓▓▓▓▓▓▓─██───█──█─█──█─██────▓▓▓▓▓▓██
//███▓▓▓▓▓▓─██───█──█─█──█─█████─▓▓▓▓▓▓██
//███▓▓▓▓▓▓─██───█──█─█──█─██────▓▓▓▓▓▓██
//─███▓▓▓▓▓─████─████─████─█████─▓▓▓▓███
//───███▓▓▓▓▓──────────────────▓▓▓▓▓▓███
//────████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████
//─────████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████
//───────████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████
//──────────████▓▓▓▓▓▓▓▓▓▓▓▓████
//─────────────███▓▓▓▓▓▓▓████
//───────────────███▓▓▓███
//─────────────────██▓██
//──────────────────███
// By the Fab Ladies team
// 
// Art by Typhoon
// Code by Cloudy
// Countless cheers & unnamed tasks by Thunderstorm
// Spirit from Typhoon's mom
contract FabLadies is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 190;
    uint256 private _price = 0.05 ether;
    bool public _paused = true;

    // wallet addresses
    address t1 = 0x1a43b44BE08e79d47104D2D8ab53936399Ba7224; // Typhoon's mom
    address t2 = 0xbF30D45f2Aae69ef3692a2955A5e85d9C5A65FD3; // Typhoon
    address t3 = 0x81dd3F3530db36174C55a0c6157D183Ab0420605; // me
    address t4 = 0xE656684962827B14fB5D0bf454358078fAC0f637; // Thunderstorm
    address t5 = 0x64C34b8443Be9D3BE9409ECa554bb1705Acd358E; // Charity

    constructor(string memory baseURI) ERC721("Fab Ladies", "FAB")  {
        setBaseURI(baseURI);

        // First 10 ladies to go to the team
        // 1 for Typhoon's mom (a tribute)
        _safeMint( t1, 0);
        // 3 for Typhoon
        _safeMint( t2, 1);
        _safeMint( t2, 2);
        _safeMint( t2, 3);
        // 3 for Cloudy
        _safeMint( t3, 4);
        _safeMint( t3, 5);
        _safeMint( t3, 6);
        // 3 for Thunderstorm
        _safeMint( t4, 7);
        _safeMint( t4, 8);
        _safeMint( t4, 9);
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 11,                              "You can mint a maximum of 10 Fab Ladies" );
        require( supply + num < 10001 - _reserved,      "Exceeds maximum Fab Ladies supply" );
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
        require( _amount <= _reserved, "Exceeds reserved Fab Lady supply" );

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
        uint charity = address(this).balance * 10 / 100;
        uint each = address(this).balance * 30 / 100;
        // 10% goes to the charity fund, the rest for each member
        require(payable(t5).send(charity));
        require(payable(t2).send(each));
        require(payable(t3).send(each));
        require(payable(t4).send(each));
    }
}