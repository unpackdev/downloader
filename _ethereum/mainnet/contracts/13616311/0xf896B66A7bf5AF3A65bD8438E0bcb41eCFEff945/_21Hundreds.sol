// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/********************
* @author: Squeebo *
********************/

import "./Delegated.sol";
import "./ERC721EnumerableLite.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";


contract _21Hundreds is Delegated, ERC721EnumerableLite, PaymentSplitter {
  using Strings for uint;

  uint public MAX_ORDER  = 20;
  uint public MAX_SUPPLY = 10000;
  uint public PRICE      = 0.12 ether;

  bool public isMainsaleActive = false;
  bool public isPresaleActive  = false;
  uint public presalePrice     = 0.1 ether;
  mapping( address => uint ) public whitelist;

  string private _baseTokenURI = '';
  string private _tokenURISuffix = '.json';

  address[] private payees = [
    0xcbAA6a102b62D6e75E6C69D8463f429867ECb2da,
    0x9c63a62849e68B5f059edb3a20A3c5a7e2C53783,
    0x4e1C0E8F7Fd15C04c897d574cb00FA4e01BDC6Bf,
    0x1f9724f3054D8f9FD28349067F796E1491d7d1C9,
    0xBFC9D96F9164376F3C49e98b36C7b3B90fE188F5,
    0x0511772bc2efe647c8fC0A17517563cF5E913F95,
    0x2F290b3C9c4e3b804aE404b39F97C73E66985ca9,
    0xC7f02456dD3FC26aAE2CA1d68528CF9764bf5598,
    0x791A5a4B459e79e2CAcf9A80EF275D15A99E3C76
  ];

  uint[] private splits = [
    370,
    225,
    223,
     50,
     50,
     40,
     25,
     12,
      5
  ];

  constructor()
    ERC721B( "21Hundreds", "21H" )
    PaymentSplitter( payees, splits ){
  }

  //external
  fallback() external payable {}

  function mint(uint quantity) external payable {
    require( isMainsaleActive,                "Main sale is not active"   );
    require( quantity <= MAX_ORDER,           "Mint/order quantity too big"             );
    
    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Mint/order quantity exceeds supply" );
    require( msg.value >= PRICE * quantity,   "Ether sent is not correct" );

    for(uint i; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }

  function presale(uint quantity) external payable {
    require( isPresaleActive,                   "Main sale is locked" );
    require( whitelist[msg.sender] > 0,         "All redemptions used" );
    require( quantity <= whitelist[msg.sender], "Not enough redemptions" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY,     "Mint/order exceeds supply"           );
    require( msg.value >= presalePrice * quantity, "Ether sent is not correct" );

    for(uint i; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
    whitelist[ msg.sender ] -= quantity;
  }

  //delegated
  function gift(uint[] calldata quantity, address[] calldata recipient) external onlyDelegates {
    require( quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity = 0;
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }

    uint supply = totalSupply();
    require( supply + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _safeMint( recipient[i], supply++, "" );
      }
    }
  }

  function setActive( bool isMainsaleActive_, bool isPresaleActive_ ) external onlyDelegates{
    require( isMainsaleActive != isMainsaleActive_ || isPresaleActive != isPresaleActive_, "New value matches old" );
    if( isMainsaleActive != isMainsaleActive_ )
      isMainsaleActive = isMainsaleActive_;

    if( isPresaleActive != isPresaleActive_ )
      isPresaleActive = isPresaleActive_;
  }

  function setMaxOrder(uint maxOrder) external onlyDelegates{
    require( MAX_ORDER != maxOrder, "New value matches old" );
    MAX_ORDER = maxOrder;
  }

  //onlyOwner
  function setMaxSupply(uint maxSupply) external onlyOwner{
    require( MAX_SUPPLY != maxSupply, "New value matches old" );
    require(maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
  }

  function setPrices(uint presalePrice_, uint mainsalePrice_ ) external onlyDelegates {
    require( presalePrice != presalePrice_ || PRICE != mainsalePrice_, "New value matches old" );

    if( presalePrice != presalePrice_ )
      presalePrice = presalePrice_;

    if( PRICE != mainsalePrice_ )
      PRICE = mainsalePrice_;
  }

  function setWhitelist(uint[] calldata quantity, address[] calldata recipient) external onlyOwner {
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );
    for( uint i; i < quantity.length; ++i ){
      whitelist[ recipient[i] ] = quantity[i];
    }
  }

  function setBaseURI(string calldata newBaseURI, string calldata newSuffix) external onlyDelegates{
    _baseTokenURI = newBaseURI;
    _tokenURISuffix = newSuffix;
  }

  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
  }
}
