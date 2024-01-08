//
//  _____ _   _ _____      _    ____  _____    ____    _    __  __ _____
// |_   _| | | | ____|    / \  |  _ \| ____|  / ___|  / \  |  \/  | ____|
//   | | | |_| |  _|     / _ \ | |_) |  _|   | |  _  / _ \ | |\/| |  _|
//   | | |  _  | |___   / ___ \|  __/| |___  | |_| |/ ___ \| |  | | |___
//   |_| |_| |_|_____| /_/   \_\_|   |_____|  \____/_/   \_\_|  |_|_____|
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Bananas.sol";
import "./Jungle.sol";

contract Apes is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;

    Bananas bananas;

    uint256 public maxFreeSupply = 500;
    uint256 public constant maxPublicSupply = 5000;
    uint256 public constant maxTotalSupply = 15000;
    uint256 public constant mintPrice = 0.029 ether;
    uint256 public constant maxPerTx = 10;
    uint256 public constant maxFreePerWallet = 10;

    address public constant dev1Address = 0xA17555Ac424f378F6C1a296cc888607621e89A1c;
    address public constant dev2Address = 0x1452f628694367d5203d48e0709b034f4da03A76;

    bool mintActive = false;
    bool public bananasMinting = false;

    mapping(address => uint256) public freeMintsClaimed; //Track free mints claimed per wallet

    string public baseTokenURI;

    constructor() ERC721("The Ape Game", "TAG") {}

    //-----------------------------------------------------------------------------//
    //------------------------------Mint Logic-------------------------------------//
    //-----------------------------------------------------------------------------//

    //Resume/pause Public Sale
    function toggleMint() public onlyOwner {
        mintActive = !mintActive;
    }

    //Public Mint
      function mint(address _referredBy, uint256 _count) public payable {
        uint256 total = _totalSupply();
        require(mintActive, "Sale has not begun");
        require(total + _count <= maxPublicSupply, "No apes left");
        require(_count <= maxPerTx, "10 max per tx");
        require(msg.value >= price(_count), "Not enough eth sent");

        for (uint256 i = 0; i < _count; i++) {
            _mintApe(msg.sender);
        }
        uint256 balance = price(_count);
        uint256 referralShare = balance.mul(10).div(100);
        if(_referredBy != 0x0000000000000000000000000000000000000000 &&_referredBy != msg.sender ){
            _referralbonus(_referredBy, referralShare);
        }
    }
    function mintNow( uint256 _count) public payable {
        uint256 total = _totalSupply();
        require(mintActive, "Sale has not begun");
        require(total + _count <= maxPublicSupply, "No apes left");
        require(_count <= maxPerTx, "10 max per tx");
        require(msg.value >= price(_count), "Not enough eth sent");

        for (uint256 i = 0; i < _count; i++) {
            _mintApe(msg.sender);
        }

    }
  function _referralbonus(address _address, uint256 _amount) private{
       payable(_address).transfer(_amount);
    }

    //Free Mint for first 500
    function freeMint(uint256 _count) public {
        uint256 total = _totalSupply();
        require(mintActive, "Public Sale is not active");
        require(total + _count <= maxFreeSupply, "No more free apes");
        require(_count + freeMintsClaimed[msg.sender] <= maxFreePerWallet, "Only 10 free mints per wallet");
        require(_count <= maxPerTx, "10 max per tx");

        for (uint256 i = 0; i < _count; i++) {
            freeMintsClaimed[msg.sender]++;
            _mintApe(msg.sender);
        }
    }

    //Public Mint until 5000
    function mintApeForBananas() public {
        uint256 total = _totalSupply();
        require(total < maxTotalSupply, "No Apes left");
        require(bananasMinting, "Minting with $bananas has not begun");
        bananas.burn(msg.sender, getBananasCost(total));
        _mintApe(msg.sender);
    }

    function getBananasCost(uint256 totalSupply) internal pure returns (uint256 cost){
        if (totalSupply < 6000)
            return 100;
        else if (totalSupply < 8000)
            return 200;
        else if (totalSupply < 10000)
            return 400;
        else if (totalSupply < 12000)
            return 800;
         else if (totalSupply < 14000)
            return 1000;
         else if (totalSupply < 15000)
            return 1200;
 
    }

    //Mint Ape
    function _mintApe(address _to) private {
        uint id = _tokenIdTracker.current();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
    }

    //Function to get price of minting a ape
    function price(uint256 _count) public pure returns (uint256) {
        return mintPrice.mul(_count);
    }

    //-----------------------------------------------------------------------------//
    //---------------------------Admin & Internal Logic----------------------------//
    //-----------------------------------------------------------------------------//

    //Set address for $Bananas
    function setBananasAddress(address bananasAddr) external onlyOwner {
        bananas = Bananas(bananasAddr);
    }

    //Internal URI function
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    //Start/Stop minting apes for $bananas
    function toggleBananasMinting() public onlyOwner {
        bananasMinting = !bananasMinting;
    }

    //Set URI for metadata
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    //Withdraw from contract
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 dev1Share = balance.mul(4).div(100);
        uint256 dev2Share = balance.mul(96).div(100);

        require(balance > 0);
        _withdraw(dev1Address, dev1Share);
        _withdraw(dev2Address, dev2Share);
    }

    //Internal withdraw
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    //Return total supply of apes
    function _totalSupply() public view returns (uint) {
        return _tokenIdTracker.current();
    }
}