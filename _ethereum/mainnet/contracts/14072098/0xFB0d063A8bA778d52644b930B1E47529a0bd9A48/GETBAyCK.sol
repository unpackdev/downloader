
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-GB721 provides low-gas     *
 *       mints + transfers              *
 ****************************************/

import "./Strings.sol";
import "./Delegated.sol";
import "./PaymentSplitterMod.sol";
import "./GB721Batch.sol";

contract GETBAyCK is Delegated, GB721Batch, PaymentSplitterMod {
  using Strings for uint256;

  uint public PRICE  = 0.05 ether;
  uint public MAX_ORDER  = 20;
  uint public MAX_SUPPLY = 1800;

  bool public isMainsaleActive;

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  address[] private addressList = [
    0x02d53ac91ef54bCA4F557aE776579799D6fB4DA3,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];
  uint[] private shareList = [
    95,
     5
  ];

  constructor()
    GB721("GET BAyCK", "GB")
    PaymentSplitterMod(addressList, shareList){
  }


  //view: external
  fallback() external payable {}

  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "GETBAyCK: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  //payable
  function mint( uint quantity ) external payable {
    require( isMainsaleActive,              "GETBAyCK: Sale is not active"        );
    require( quantity <= MAX_ORDER,         "GETBAyCK: Order too big"             );
    require( msg.value >= PRICE * quantity, "GETBAyCK: Ether sent is not correct" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "GETBAyCK: Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _mint( msg.sender );
    }
  }


  //onlyDelegates
  function mintTo(address[] calldata recipient, uint[] calldata quantity) external payable onlyDelegates{
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
    isMainsaleActive = isActive_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setMax(uint maxOrder, uint maxSupply) external onlyDelegates{
    require( maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_ORDER = maxOrder;
    MAX_SUPPLY = maxSupply;
  }

  function setPrice( uint ethPrice ) external onlyDelegates{
    PRICE = ethPrice;
  }


  //private
  function _mint( address to ) private {
    uint tokenId = owners.length;
    owners.push( to );
    emit Transfer(address(0), to, tokenId);
  }
}
