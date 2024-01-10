//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract AES1 is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    
    uint public constant MAX_SUPPLY = 10435;
    uint public constant PRICE = 0.07 ether;
    uint public constant MAX_PER_MINT = 50;
    
    string public baseTokenURI;
    
    constructor(string memory baseURI) ERC721("AES Apes", "AES1") {
        setBaseURI(baseURI);
    }
    
    function reserveNFTs() public onlyOwner {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(30) < MAX_SUPPLY, "Not enough NFTs left to reserve");

        for (uint i = 0; i < 30; i++) {
            _mintSingleNFT();
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    
    function mintNFTs(uint _count) public payable {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }
    
    function _mintSingleNFT() private {
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
    
     address private constant payoutAddress1 =
        0xa0e17E640fA14677b455349d03c93F94A0ebcA9f;
    address private constant payoutAddress2 =
        0xb613FB04cE314B401E9A3b226A29a47d293E7E19;
    address private constant payoutAddress3 =
        0x7DF1Ce077D75709A0fC0E0A61f1E157c2b226BFd;


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAddress1), balance / 3);
        Address.sendValue(payable(payoutAddress2), balance / 3);
        Address.sendValue(payable(payoutAddress3), balance / 3);
    }
    
}