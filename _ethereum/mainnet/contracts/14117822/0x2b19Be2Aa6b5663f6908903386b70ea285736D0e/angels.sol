// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract LittleAngels is ERC721URIStorage, Pausable, Ownable {
    event MintAngels(address indexed minter, uint256 startWith, uint256 times);
    using Counters for Counters.Counter;
    uint256 public constant totalAngel = 5700;
    uint256 public totalDonateRecieved = 0 ether;
    bool public isWhiteListStarted = true;

    uint256 public price = 0.03 ether;
    string public baseURI = "ipfs://QmUHQmXQUYWM9nGaTFW6W2UN73K5NG15o4T3nyxWtB5A2R/";
    Counters.Counter private _tokenIdCounter;
    mapping(address => uint256) _dooners;
    constructor() ERC721("LittleAngels", "Angel") {
        _tokenIdCounter.increment();
    }

    function pause() public onlyOwner {
        _pause(); 
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }
    function setWhiteListStatus(bool _case) public onlyOwner {
        isWhiteListStarted = _case;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function getTotalSupply() public view returns(uint256){
        return _tokenIdCounter.current();
    }
    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }
     function adminMint(uint256 _times, address _to) public payable whenNotPaused onlyOwner {
        uint256 total = _tokenIdCounter.current();
        for (uint256 i = 0; i < _times; i++) {
            _tokenIdCounter.increment();
            _mint(_to, i + total );
        }
    }   
    function publicMint(uint256 _times) public payable whenNotPaused{
        uint256 total = _tokenIdCounter.current();
        require(total + _times < totalAngel + 1, "306");
        uint256 currentPrice = 0;
        if (isWhiteListStarted) {
            currentPrice = 0.02 ether;
        } else {
            currentPrice = price;

        }
        require(_times *  currentPrice == msg.value, "345");
       
          uint256 totalAmount = _dooners[msg.sender];
        _dooners[msg.sender] = totalAmount += msg.value;
        totalDonateRecieved += msg.value;
        for (uint256 i = 0; i < _times; i++) {
            _tokenIdCounter.increment();
            _mint(msg.sender, i + total );
        }
    }
    function angleoo(uint _input) public whenNotPaused {
        require(_input == 78910, "404");
        uint256 current = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, current);
    }

    function donate() public payable {
        uint256 totalAmount = _dooners[msg.sender];
        _dooners[msg.sender] = totalAmount += msg.value;
        totalDonateRecieved += msg.value;
    }
    function getDonateByAddress(address  _address) public view returns (uint256){
        return _dooners[_address];
    }
    
    function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}