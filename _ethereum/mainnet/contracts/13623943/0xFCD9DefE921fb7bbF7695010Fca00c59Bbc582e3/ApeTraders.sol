// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract ApeTraders is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxSupply = 7777;

    string public _provenanceHash;
    string public _baseURL;
    bool public _presaleStarted = true;
    bool public _paused = true;
    mapping(address => bool) public presaleList;
    
    constructor() ERC721("Ape Traders", "APETRADERS") {}

    function mint(uint256 count) public payable {
        require(!_paused, "Minting is paused");
        require(_tokenIds.current() + count <= _maxSupply, "Max limit");
        require(count > 0, "Should mint at least 1");
        require(msg.value >= count * 0.07 ether, "Insufficient payment");
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }
        bool success = false;
        (success,) = owner().call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        _provenanceHash = provenanceHash;
    }

    function setBaseURL(string memory baseURI) public onlyOwner {
        _baseURL = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function flipPresaleState() public onlyOwner {
         _presaleStarted = !_presaleStarted;
    }

    function flipPausedState() public onlyOwner {
         _paused = !_paused;
    }

    function mintPresale(uint256 count) public payable {
        require(_presaleStarted, "Presale minting is closed");
        require(_tokenIds.current() + count <= _maxSupply, "Max limit");
        require(count > 0, "Should mint at least 1");
        require(presaleList[msg.sender] == true, "Address is not whitelisted");
        require(msg.value >= count * 0.07 ether, "Insufficient payment");
        for (uint i = 0; i < count; i++) {
           _tokenIds.increment();
           _mint(msg.sender, _tokenIds.current());
        }
        bool success = false;
        (success,) = owner().call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }
  
    function addToPresaleList(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
          presaleList[addresses[i]] = true;
        }
    }

    function reserve(uint256 count) public onlyOwner {
        require(_tokenIds.current() + count <= _maxSupply, "Max limit");
        require(count > 0 , "Count cannot be zero");
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(owner(), _tokenIds.current());
        }
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        bool success = false;
        (success,) = owner().call{value : balance}("");
        require(success, "Failed to send to owner");
    }

}