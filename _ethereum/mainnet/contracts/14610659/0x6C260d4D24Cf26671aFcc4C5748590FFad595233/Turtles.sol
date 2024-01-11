
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/********************************
 * @author: squeebo_nft         *
 *   Blimpie provides low-gas   *
 *       mints + transfers      *
 ********************************/

import "./Strings.sol";
import "./Delegated.sol";
import "./PaymentSplitterMod.sol";
import "./T721Batch.sol";

interface IERC20Proxy{
  function mintToAccount( address account, uint tw ) external;
}

contract QwertyTurtles2 is Delegated, T721Batch, PaymentSplitterMod {
  using Strings for uint16;
  using Strings for uint256;

  uint public ETH_PRICE  = 0 ether;
  uint public MAX_ORDER  = 10;
  uint public MAX_SUPPLY = 3888;

  // //seconds
  bool public isActive;

  string private _tokenURIPrefix = "https://qwertyturtles.mypinata.cloud/ipfs/QmUYgttPgmwFgkGq9j95EAoCCLNewnYVQUw1xadbFW8QRG/";
  string private _tokenURISuffix = ".json";

  address[] private addressList = [
    0x91f30728B869f2dDF36De0dB1c9C8f51d84606c2,
    0x46462Ee2B2e26561360ee7F629Da0Ff7E1F02B76,
    0xF403829905A2799076f741b2397d6c5f0c34D224
  ];
  uint[] private shareList = [
    90,
    5,
    5
  ];

  constructor()
    T721("QwertyTurtles2", "QT2")
    PaymentSplitterMod(addressList, shareList){
  }


  //view: external
  fallback() external payable {}

  //view: IERC721Enumerable
  function totalSupply() public view override returns( uint totalSupply_ ){
    return tokens.length;
  }

  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "QuertyTurtles: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  //payable
  function mint( uint quantity ) external payable {
    require( isActive,                          "QuertyTurtles: Sale is not active"        );
    require( quantity <= MAX_ORDER,             "QuertyTurtles: Order too big"             );
    require( msg.value >= ETH_PRICE * quantity, "QuertyTurtles: Ether sent is not correct" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "QuertyTurtles: Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _mint( msg.sender );
    }
  }

  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity < MAX_SUPPLY, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _mint( recipient[i] );
      }
    }
  }

  function setActive(bool isActive_) external onlyDelegates{
    require( isActive != isActive_, "New value matches old" );
    isActive = isActive_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setMaxOrder(uint maxOrder, uint maxSupply) external onlyDelegates{
    require( maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_ORDER = maxOrder;
    MAX_SUPPLY = maxSupply;
  }

  function setPrice( uint ethPrice ) external onlyDelegates{
    ETH_PRICE = ethPrice;
  }

  //private
  function _beforeTokenTransfer(address from, address to, uint tokenId) internal override{
    
  }

  function _mint( address to ) private {
    uint tokenId = tokens.length;
    _beforeTokenTransfer(address(0), to, tokenId);
    tokens.push(Token( to, uint16(tokenId), 0));
    emit Transfer(address(0), to, tokenId);
  }
}
