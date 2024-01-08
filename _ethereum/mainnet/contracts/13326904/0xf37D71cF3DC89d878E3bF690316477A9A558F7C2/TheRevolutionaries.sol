// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TheRevolutionaries is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    string public provenance = "06a87095a9dc3902cd29e91baf8af956df41f9f3834e39ef4277eb3564fda285"; // metadata dir sha256 hash
    uint256 private _price = 0.01 ether;
    uint256 public constant max_per_mint = 20;
    uint256 public constant max_characters = 10000;
    uint256 public _reveal_timestamp;
    bool public _paused = true;

    address public constant creatorAddress = 0x98Dcb966DE86E5DB06BED73A9Bc497D96A6115B8;
    address public constant devAddress = 0x4238501696C0dcDcE5e10788C61Bb7Aa06cEfA08;

    event TheBirthOfARevolutionary(uint256 indexed id);

    constructor(string memory baseURI) ERC721("The Revolutionaries", "REVOLUTION") {
        setBaseURI(baseURI);
    }

    function mintRevolutionary(uint256 _count) public payable {
        uint256 total = _totalSupply();
        require( !_paused,                            "Sale is paused" );
        require( _count > 0,                          "Must mint at least one token" );
        require( _count <= max_per_mint,              "Can only mint 20 tokens max" );
        require( total <= max_characters,             "Maximum supply reached" );
        require( total + _count < max_characters,     "Purchase would exceed the maximum supply" );
        require( msg.value >= _price * _count,        "Ether value sent is below required amount" );

        for(uint256 i; i < _count; i++){
            _safeMint( msg.sender, total + i );
            emit TheBirthOfARevolutionary(total);
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

    // Set RevealTimestmp
    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        _reveal_timestamp = revealTimeStamp;
    } 

    // Set the provenance hash
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenance = _provenanceHash;
    }

    // Safety net for big fluctuations in ETH price
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    // Team Allocation and Giveaways
    function reserve() public onlyOwner {        
        uint256 total = _totalSupply();
        for (uint256 i = 0; i < 50; i++) {
            _safeMint(msg.sender, total + i);
        }
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

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function _totalSupply() internal view returns (uint) {
        return totalSupply();
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _half = address(this).balance / 2;
        require(payable(creatorAddress).send(_half));
        require(payable(devAddress).send(_half));
    }

}
