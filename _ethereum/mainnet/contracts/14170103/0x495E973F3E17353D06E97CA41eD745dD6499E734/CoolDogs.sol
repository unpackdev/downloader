// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CoolDogs is ERC721Enumerable, Ownable {
    uint256 public constant MAX_COOLDOGS = 9999;
    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 200;
    bool public _paused = true;

    // withdraw addresses
    address D = 0xe4bF593Ad8Bd6CeF78Db83185B77647F7be78920;
    address Z = 0x580B60F163D16365C3dB2f8B289d631A5301B3C7;
    address G = 0x38c8456cc86f492CB778aeD5Bae174c91eB8e13e;
    address L = 0xAc7A7cD8f083e74845c70dB4478BfEAE112468F7;
 
    constructor(string memory baseURI) ERC721("Cool Dogs", "COOLDOGS")  {
        setBaseURI(baseURI);
    }

    function adopt(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,"Sale paused" );
        require( num < 21, "You can adopt a maximum of 20 CoolDogs" );
        require( supply + num < MAX_COOLDOGS - _reserved, "Exceeds maximum CoolDogs supply" );
        require( msg.value >= price() * num,"Ether sent is not correct" );

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

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function price() public view returns (uint256){
        uint256 totalnow = totalSupply();

        if (totalnow >= 9900) {
            return 180000000000000000;         // 9900-9999:  0.18 ETH
        } else if (totalnow >= 9500) {
            return 140000000000000000;         // 9500-9899:  0.14 ETH
        } else if (totalnow >= 7500) {
            return 100000000000000000;         // 7500-9499:  0.10 ETH
        } else if (totalnow >= 3500) {
            return 80000000000000000;          // 3500-7499:  0.08 ETH 
        } else if (totalnow >= 1500) {
            return 60000000000000000;          // 1500-3499:  0.06 ETH 
        } else if (totalnow >= 500) {
            return 40000000000000000;          // 500-1499:   0.04 ETH 
        } else {
            return 20000000000000000;          // 1 - 499     0.02 ETH
        }
    }

    function give(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved dogs supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdraw() public payable onlyOwner {
        uint256 _each = address(this).balance / 4;
        require(payable(D).send(_each));
        require(payable(Z).send(_each));
        require(payable(G).send(_each));
        require(payable(L).send(_each));
    }
}