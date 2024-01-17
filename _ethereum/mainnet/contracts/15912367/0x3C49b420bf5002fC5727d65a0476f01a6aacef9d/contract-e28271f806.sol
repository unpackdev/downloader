// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/// @custom:security-contact dev@shadowysupercoder.dev
contract HappyBoiz is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant PRICE = 0.02 ether;

    address public crossmintAddress;

    constructor() ERC721("HappyBoiz", "HAPPY") {
        _tokenIdCounter.increment();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://bafybeic7eyqajd6xltuaswons3lppumydtfolquaoar7a6fzt2udqtxixq.ipfs.nftstorage.link/";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function mint(address to) public payable {
        require(_tokenIdCounter.current() < MAX_SUPPLY, "The collection is sold out");
        require(msg.value >= PRICE, "Ether value sent is not correct");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function ownerMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);   
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

  function crossmint(address _to) public payable {
    require(PRICE == msg.value, "Incorrect value sent");
    require(_tokenIdCounter.current() + 1 <= MAX_SUPPLY, "No more left");
    // NOTE THAT the address is different for ethereum, polygon, and mumbai
    // ethereum (all)  = 0xdab1a1854214684ace522439684a145e62505233 
    // polygon mainnet = 0x12A80DAEaf8E7D646c4adfc4B107A2f1414E2002
    // polygon mumbai  = 0xDa30ee0788276c093e686780C25f6C9431027234  
    require(msg.sender == crossmintAddress, 
      "This function is for Crossmint only."
    );

    uint256 newTokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();

    _safeMint(_to, newTokenId);
  }
    
  // include a setting function so that you can change this later
  function setCrossmintAddress(address _crosssmintAddress) public onlyOwner {
      crossmintAddress = _crosssmintAddress;
  }
}