
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: Squeebo                     *
 * @team:   Golden X                    *
 ****************************************/

import "./Delegated.sol";
import "./ERC1155.sol";
import "./PaymentSplitter.sol";

contract ApertusSphera is Delegated, ERC1155, PaymentSplitter{
  struct Token{
    uint burnPrice;
    uint mintPrice;
    uint balance;
    uint maxWallet;
    uint supply;

    bool isBurnActive;
    bool isMintActive;

    string name;
    string uri;

    mapping(string => string) metadata;
  }

  Token[] public tokens;

  address[] private payees = [
    0x608D6C1f1bD9a99565a7C2ED41B5E8e1A2599284,
    0x42e98CdB46444c96B8fDc93Da2fcfd9a77FA9575,
    0xBd855c639584686315cb5bdfC7190057BC2a2A08,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];

  uint[] private splits = [
    85,
     5,
     5,
     5
  ];

  constructor()
    ERC1155("")
    PaymentSplitter( payees, splits ){
  }


  //public
  function uri(uint id) public override view returns (string memory){
    require(id < tokens.length, "Specified token (id) does not exist" );
    return tokens[id].uri;
  }


  //external
  fallback() external payable {}

  function burn( uint id, uint quantity ) external payable{
    require( id < tokens.length,                           "Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.isBurnActive,                      "Sale is not active"        );
    require( msg.value >= token.burnPrice * quantity, "Ether sent is not correct" );

    _burn( _msgSender(), id, quantity );
    token.balance -= quantity;
    token.supply -= quantity;
  }

  function mint( uint id, uint quantity ) external payable{
    require( id < tokens.length,                           "Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.isMintActive,                      "Sale is not active"        );
    require( token.balance + quantity <= token.supply, "Not enough supply"         );
    require( msg.value >= token.mintPrice * quantity, "Ether sent is not correct" );

    _mint( _msgSender(), id, quantity, "" );
    token.balance += quantity;
  }

  function mintTo( address[] calldata accounts, uint[] calldata ids, uint[] calldata quantities ) external payable onlyDelegates {
    require( accounts.length == ids.length,   "Must provide equal accounts and ids" );
    require( ids.length == quantities.length, "Must provide equal ids and quantities");

    for(uint i; i < ids.length; ++i ){
      require( ids[i] < tokens.length, "Specified token (id) does not exist" );

      Token storage token = tokens[ids[i]];
      require( token.balance + quantities[i] <= token.supply, "Not enough supply" );
      _mint( accounts[i], ids[i], quantities[i], "" );
      token.balance += quantities[i];
    }
  }


  //delegated
  function setActive(uint id, bool isBurnActive, bool isMintActive) external onlyDelegates{
    require( id < tokens.length, "Specified token (id) does not exist" );
    require( tokens[id].isBurnActive != isBurnActive || tokens[id].isMintActive != isMintActive, "New value matches old" );
    tokens[id].isBurnActive = isBurnActive;
    tokens[id].isMintActive = isMintActive;
  }

  function setPrice(uint id, uint burnPrice, uint mintPrice) external onlyDelegates{
    require( id < tokens.length, "Specified token (id) does not exist" );
    require( tokens[id].burnPrice != burnPrice || tokens[id].mintPrice != mintPrice, "New value matches old" );
    tokens[id].burnPrice = burnPrice;
    tokens[id].mintPrice = mintPrice;
  }

  function setSupply(uint id, uint maxWallet, uint supply) external onlyDelegates{
    require( id < tokens.length, "Specified token (id) does not exist" );

    Token storage token = tokens[id];
    require( token.maxWallet != maxWallet || token.supply != supply,  "New value matches old" );
    require( token.balance <= supply, "Specified supply is lower than current balance" );
    token.maxWallet = maxWallet;
    token.supply = supply;
  }

  function setToken(uint id, string calldata name, string calldata uri_,
    uint maxWallet, uint supply,
    bool isBurnActive, uint burnPrice,
    bool isMintActive, uint mintPrice ) external onlyDelegates{
    require( id < tokens.length || id == tokens.length, "Invalid token id" );
    if( id == tokens.length )
      tokens.push();

    Token storage token = tokens[id];
    require( token.balance <= supply, "Specified supply is lower than current balance" );

    token.name         = name;
    token.uri          = uri_;
    token.isBurnActive = isBurnActive;
    token.burnPrice    = burnPrice;
    token.isMintActive = isMintActive;
    token.mintPrice    = mintPrice;

    token.maxWallet    = maxWallet;
    token.supply       = supply;
  }

  function setTokenMetadata(uint id, string[] calldata keys, string[] calldata values ) external onlyDelegates{
    require( id < tokens.length || id == tokens.length, "Invalid token id" );
    require( keys.length == values.length, "Must provide equal keys and values" );
    Token storage token = tokens[id];
    for( uint i; i < keys.length; ++i ){
      token.metadata[ keys[i] ] = values[i];
    }
  }

  function setURI(uint id, string calldata uri_) external onlyDelegates{
    require( id < tokens.length, "Specified token (id) does not exist" );
    tokens[id].uri = uri_;
  }
}
