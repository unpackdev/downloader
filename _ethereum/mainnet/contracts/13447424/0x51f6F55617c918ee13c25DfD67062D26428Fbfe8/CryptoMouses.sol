// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CryptoMouses is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 10;
    uint256 private _price = 0.08 ether;
    bool private _paused = true;

    // withdraw addresses
    address t1 = 0x39d621a1077EAa59C008E063E7D7EB4bB6110bC4;    //owner address
    address t2 = 0x1E7f21B49917d38AeDA79d83Cc51C53AF95A03fc;    //dev team address
    address team_rewards_wallet = 0x0B0d39792DFcF590c7abf1bC934B3B0Ff4aB46D1; //team rewards of NFTs

    // 9999 mouses in total
    constructor(string memory baseURI) ERC721("Crypto Mouses", "MOUSE")  {
        setBaseURI(baseURI);

        // These first 12 mouese for team
        for(uint256 i = 0; i < 12; i++){
            _safeMint( team_rewards_wallet, i );
        }
    }

    function mintCryptoMouse(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 21,                              "You can mint a maximum of 20 Crypto Mouses" );
        require( supply + num < 999 - _reserved,      "Exceeds maximum Mouses supply" );
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
        require( _amount <= _reserved, "Exceeds reserved Mouse supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }
    
    function isPaused() public view returns (bool){
        return _paused;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _t1 = address(this).balance / 100 * 85;
        uint256 _t2 = address(this).balance / 100 * 15;
        require(payable(t1).send(_t1));
        require(payable(t2).send(_t2));
    }
}