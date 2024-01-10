// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import  "./PuzzleGenerator.sol";

/** 
 * @title Mondrian Puzzles
 */
contract MondrianPuzzle is ERC721, Ownable {
    using Counters for Counters.Counter;

    constructor() ERC721("Mondrian Puzzles", "MPZL") {}

    uint public price = 0.01 ether;
    uint public constant YEARLY_SUPPLY = 1024;
    Counters.Counter internal tokenIdCounter;
    mapping(uint => Counters.Counter) internal yearlyCounts;
    mapping(uint => Counters.Counter) internal yearlyFreebies;
    

    function _performMint(address destination) internal  {
        require(currentYearSupply() < YEARLY_SUPPLY, "Yearly quota reached!");
        require(tokenIdCounter.current() < YEARLY_SUPPLY*5, "Reached max tokens!");
        
        _safeMint(destination, tokenIdCounter.current());
        yearlyCounts[_getCurrentYear()].increment();        
        tokenIdCounter.increment();
        
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        string memory encodedJSON =  PuzzleGenerator.generateMetadata(tokenId);
        return string(abi.encodePacked("data:application/json;base64,", encodedJSON));
    }

    function _getCurrentYear() internal view returns (uint) {
        return 1970 + block.timestamp / 31556926;
       
    }
    

    function currentYearSupply() public view returns (uint) {
        return yearlyCounts[_getCurrentYear()].current();
    }    

    function currentYearFreeSupply() public view returns (uint) {
        return yearlyFreebies[_getCurrentYear()].current();
    }   


    function mintFor(address walletAddress) public payable virtual {
        require(msg.value >= price, "Price not met.");
        _performMint(walletAddress);
    }

    function mintForFree() public virtual {
        require(yearlyFreebies[_getCurrentYear()].current() < YEARLY_SUPPLY/256, "No more freebies this year.");
        yearlyFreebies[_getCurrentYear()].increment(); 
        _performMint(msg.sender);
    }

    function mint(address destination) public onlyOwner {
        _performMint(destination);
    }
    
    function adjustPrice(uint newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function  total() public view returns(uint)
    {
        return tokenIdCounter.current();
    }
}