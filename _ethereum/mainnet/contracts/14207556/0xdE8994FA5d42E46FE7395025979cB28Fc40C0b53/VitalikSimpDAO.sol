// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";


contract VitalikSimpDAO is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;

    uint public constant MAX_SUPPLY = 999;
    uint public constant PRICE = 0.1 ether;

    string public baseTokenURI;
    bool public paused = true;

    event NewVitalikNFTMinted(address sender, uint256 tokenId);

    
    constructor(string memory baseURI) ERC721("VitalikSimpDAO", "VSD") {
        setBaseURI(baseURI);
    }

    function reserveNFTs() public onlyOwner {
        uint totalMinted = _tokenIds.current();
        require(
            totalMinted.add(10) <= MAX_SUPPLY, "Not enough NFTs"
        );
        for (uint i = 0; i < 10; i++) {
            _mintSingleNFT();
        }
    }
    
    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
     return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }  

    function mintNFTs(uint _count) public payable {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Everything has been minted already, sorry!");
        require(_count > 0, "You need to enter a positive value!");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase the NFTs!");
        require(!paused, "The contract is paused at the moment!");


        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
        
        emit NewVitalikNFTMinted(msg.sender, _tokenIds.current());
    }

    function _mintSingleNFT() private{
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }
    
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
     return tokensId;
    }

    function withdraw() public payable onlyOwner{
        uint balance = address(this).balance;
        require(balance > 0, "Nothing left to withdraw!");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function getTokenNumber() public view returns(uint256) {
        return _tokenIds.current();
    }

    function getMaxSupply() public pure returns(uint256) {
        return MAX_SUPPLY;
    }

    function getPaused() public view returns (bool) {
        return paused;
    }
}