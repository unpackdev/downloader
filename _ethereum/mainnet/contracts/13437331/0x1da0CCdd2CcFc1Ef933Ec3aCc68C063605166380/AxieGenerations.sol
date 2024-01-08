// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";
// import "./console.sol";

//  ______                         ____                                      __                                
// /\  _  \         __            /\  _`\                                   /\ \__ __                          
// \ \ \L\ \  __  _/\_\     __    \ \ \L\_\    __    ___      __  _ __   __ \ \ ,_/\_\    ___    ___     ____  
//  \ \  __ \/\ \/'\/\ \  /'__`\   \ \ \L_L  /'__`\/' _ `\  /'__`/\`'__/'__`\\ \ \\/\ \  / __`\/' _ `\  /',__\ 
//   \ \ \/\ \/>  </\ \ \/\  __/    \ \ \/, /\  __//\ \/\ \/\  __\ \ \/\ \L\.\\ \ \\ \ \/\ \L\ /\ \/\ \/\__, `\
//    \ \_\ \_/\_/\_\\ \_\ \____\    \ \____\ \____\ \_\ \_\ \____\ \_\ \__/.\_\ \__\ \_\ \____\ \_\ \_\/\____/
//     \/_/\/_\//\/_/ \/_/\/____/     \/___/ \/____/\/_/\/_/\/____/\/_/\/__/\/_/\/__/\/_/\/___/ \/_/\/_/\/___/ 

// created by @trumperyD
// axiegen.axietrends.com 
// October 2021
// With thanks to @maxbrand99, @yuukiandhisaxie, @davevsaxie, @fuujinaxs and @fund911                                                                                                         
            
contract AxieGenerations is ERC721, Ownable  {
  using Counters for Counters.Counter;
  using SafeMath for uint;

  Counters.Counter private _tokenIds;
  string public baseTokenURI;
  uint public MAX_TOKENS = 3416;
  bool public hasSaleStarted = false;
  uint public SINGLE_PRICE = 15000000000000000; // 0.015 Eth
  uint public COSTCO_PRICE = 10000000000000000; // 0.01 ETH


  constructor(string memory baseURI) ERC721 ("Axie Generations", "AGEN") {
    baseTokenURI = baseURI;
    // console.log("Contract deployed");
  }

  function getCurrentCount() public view returns (uint256) {
    return _tokenIds.current();
  }
  
  function startSale(bool ss) public {
        hasSaleStarted = ss;
  }

  function calculatePrice(uint256 numTokens) public view returns (uint256) {
    require(hasSaleStarted == true, "Sale hasn't started");

    uint tokenPrice;

    if (numTokens < 10) {
        tokenPrice = SafeMath.mul(SINGLE_PRICE, numTokens);
    } else if (numTokens >= 10 ) {
        tokenPrice = SafeMath.mul(COSTCO_PRICE, numTokens);
    }     
    return tokenPrice; 
  }

  function tokensMinted() public view returns(uint) {
    uint tl = getCurrentCount();  
    return tl;
  } 

  function mint(uint256 numTokens) public payable {
    require(hasSaleStarted == true, "Sale hasn't started");
    require(SafeMath.add(getCurrentCount(), numTokens) <= MAX_TOKENS , "Exceeds maximum token supply.");
    require(numTokens > 0, "Cannot mint 0 tokens");
    require(msg.value >= calculatePrice(numTokens), "Amount of Ether sent is not correct.");
    
    for (uint i = 0; i < numTokens; i++) {
        uint mintIndex = getCurrentCount();
        _safeMint(msg.sender, mintIndex);
        _tokenIds.increment();
    }
  }

  function reserveMint(uint256 numTokens) public onlyOwner {
    require(SafeMath.add(getCurrentCount(), numTokens) <= MAX_TOKENS , "Exceeds maximum token supply.");
    require(numTokens > 0, "Cannot mint 0 tokens");
    
    for (uint i = 0; i < numTokens; i++) {
        uint mintIndex = getCurrentCount();
        _safeMint(msg.sender, mintIndex);
        _tokenIds.increment();
    }
  }
  
  function withdraw() public onlyOwner {
    uint256 _balance = address(this).balance;
    address payable _sender = payable(_msgSender());
    _sender.transfer(_balance);
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
      return baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
      baseTokenURI = baseURI;
  }
}