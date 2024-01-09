// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   X-11                        *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./Strings.sol";
import "./ERC721Batch.sol";
import "./PaymentSplitterMod.sol";

contract Theotokos is ERC721Batch, PaymentSplitterMod {
  using Strings for uint;

  uint public MAX_ORDER = 20;
  uint public MAX_SUPPLY = 11111;
  uint public PRICE = 0.01531 ether;

  bool public isMainsaleActive = false;

  string private _tokenURIPrefix = "https://ipfs.io/ipfs/QmcA65bVZSHBpfx5gZpaTCHZGuXu2KgTVUoowmfRAKrqyw?";
  string private _tokenURISuffix;

  address[] private addressList = [
    0x42482574E038334D1d2c0944E7Daf3C19D21F83a,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];

  uint[] private shareList = [
    95,
     5
  ];

  constructor()
    Delegated()
    ERC721( "Theotokos", "THEOS" )
    PaymentSplitterMod( addressList, shareList ){
  }


  //safety first
  fallback() external payable {}


  //view
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "Theotokos: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }


  //payable
  function mint( uint quantity ) public payable{
    require( isMainsaleActive, "Public sale is not active" );
    require( quantity <= MAX_ORDER,         "Order too big" );
    require( msg.value >= quantity * PRICE, "Not enough ETH sent" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Order exceeds supply" );
    for( uint i; i < quantity; ++i ){
      _mint( msg.sender, supply++ );
    }
  }



  //delegated
  function mintTo( address[] calldata accounts, uint[] calldata quantities ) external payable onlyDelegates{
    require(accounts.length == quantities.length, "PE: Must provide equal accounts and quantities" );

    uint total;
    for(uint i; i < quantities.length; ++i){
      total += quantities[i];
    }

    uint supply = totalSupply();
    require( supply + total <= MAX_SUPPLY, "Order exceeds supply" );
    for(uint i; i < accounts.length; ++i ){
      for( uint q; q < quantities[i]; ++q ){
        _mint( accounts[i], supply++ );
      }
    }
  }

  function setActive( bool isActive ) external onlyDelegates{
    isMainsaleActive = isActive;
  }

  function setMax( uint maxOrder, uint maxSupply ) external onlyDelegates{
    MAX_ORDER  = maxOrder;
    MAX_SUPPLY = maxSupply;
  }

  function setPrice( uint price ) external onlyDelegates{
    PRICE = price;
  }

  function setUri( string calldata prefix, string calldata suffix ) external onlyDelegates{
    _tokenURIPrefix = prefix;
    _tokenURISuffix = suffix;
  }


  //onlyOwner
  function addPayee( address account, uint shares ) external onlyOwner {
    _addPayee( account, shares );
  }

  function setPayee( uint index, address account, uint newShares ) external onlyOwner {
    _setPayee( index, account, newShares );
  }
}
