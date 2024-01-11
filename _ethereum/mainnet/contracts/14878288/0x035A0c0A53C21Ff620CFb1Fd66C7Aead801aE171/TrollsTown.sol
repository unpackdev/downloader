//    ,       ..    ,                       , ._
//   -+-._. _ || __-+- _ .    ,._    .    ,-+-|,
//    | [  (_)||_)  | (_) \/\/ [ ) *  \/\/  | | 

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TrollsTown is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public population = 6969;
    uint256 public weWillSee = 500;
    uint256 public upforGrabs = 10;

    bool public awakening = true;

    string public baseURI = "ipfs://bafybeifayvtzgfzvljmeja2f2omyvteyflhk4b76uplm77fnvzxzil72ie";

    constructor() ERC721A("trollstown.wtf", "TTWTF") {}

    /* MINT NFT */

    function nowWeKnow(address to ,uint256 amount) external onlyOwner{
        uint256 supply = totalSupply();
        require(supply + amount <= population,"Sold Out");
        require(amount <= weWillSee,'No team mints left');
        _safeMint(to,amount);
        weWillSee-=amount;
    }

    function hatchEgg(uint256 amount) external payable nonReentrant{

        uint256 supply = totalSupply();
        uint256 minted = numberMinted(msg.sender);

        require(awakening,"Public Sale Is Not Active");
        require(supply + amount + weWillSee <= population,"Public Mint Sold Out!");
        require(minted + amount <= upforGrabs,"You've Maxed Out Your Mints");

        _safeMint(msg.sender,amount);
    }
     /* END MINT */

    //SETTERS

    function nowYouKnow(uint256 _newSupply) external onlyOwner {
        require(_newSupply <= weWillSee,"Can't Increase Supply");
        weWillSee = _newSupply;
    }

    function wakeUp(bool _status) public onlyOwner {
        awakening = _status;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function feelingGenerous(uint256 _newSupply) external onlyOwner {
        upforGrabs = _newSupply;
    }

    //END SETTERS

    // GETTERS

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // END GETTERS
    // FACTORY

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, "/", _tokenId.toString(), ".json"));
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    
}