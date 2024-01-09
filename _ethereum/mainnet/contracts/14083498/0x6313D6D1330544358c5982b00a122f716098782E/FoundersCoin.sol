
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
import "./PaymentSplitterMod.sol";
import "./Signed.sol";
import "./FC721Batch.sol";

import "./console.sol";

contract FoundersCoin is FC721Batch, PaymentSplitterMod, Signed {
  using Strings for uint256;

  uint public PRICE  = 0.04 ether;
  uint public MAX_ORDER  = 6;
  uint public MAX_SUPPLY = 1200;
  uint public MAX_WALLET = 6;

  bool public isMainsaleActive = false;

  string private _tokenURIPrefix = 'https://cryptodelinkuents.com/metadata/';
  string private _tokenURISuffix = '.json';

  address[] private addressList = [
    0xed5CCAf5FF3D360eE7cF2C10bA9888266eeC78d0,
    0x785cB4961B71c9A3e1661E5E63D7198A48036348
  ];
  uint[] private shareList = [
    90,
    10
  ];

  constructor()
    FC721("Founders Coin", "")
    PaymentSplitterMod(addressList, shareList){
  }


  //view: external
  fallback() external payable {}

  function ownerPoints( address owner ) public view returns ( uint ){
    uint points;
    for( uint i; i < balances[owner].length; ++i ){
      points += tokens[i ].points;
    }
    return points;
  }

  function tokenPoints( uint tokenId ) external view returns ( uint16 ){
    return tokens[ tokenId ].points;
  }

  function isLocked() external view returns( bool ){
    return !isMainsaleActive;
  }

  function maxOrder() external view returns( uint ){
    return MAX_ORDER;
  }

  function maxWallet() external view returns( uint ){
    return MAX_WALLET;
  }

  function price() external view returns( uint ){
    return PRICE;
  }

  function TOTAL_SUPPLY() external view returns( uint ){
    return MAX_SUPPLY;
  }



  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "FoundersCoin: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }


  //payable
  function mint( uint quantity ) external payable {
    require( isMainsaleActive,              "FoundersCoin: Sale is not active" );
    require( quantity <= MAX_ORDER,         "FoundersCoin: order too big"             );
    require( msg.value >= PRICE * quantity, "FoundersCoin: ether sent is not correct" );
    require( balances[ msg.sender ].length + quantity <= MAX_WALLET, "FoundersCoin: don't be greedy" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "FoundersCoin: mint/order exceeds supply" );

    unchecked{
      for(uint i; i < quantity; ++i){
        _mint( msg.sender, tokens.length );
      }
    }
  }


  //onlyDelegates
  function addPoints(uint fromTokenId, uint toTokenId, uint16 points ) external onlyDelegates {
    require( toTokenId < totalSupply(), "Invalid end token" );
    for( ; fromTokenId <= toTokenId; ++fromTokenId ){
      tokens[fromTokenId].points += points;
    }
  }

  function usePoints(address owner, uint points) external onlyDelegates{
    require( points > 0, "Invalid points" );

    for(uint i; i < balances[owner].length; ++i){
      Token storage token = tokens[ balances[owner][i] ];
      if( points > token.points ){
        points = points - token.points;
        token.points = 0;
      }
      //points <= token.points
      else{
        token.points = token.points - uint16(points);
        points = 0;
        break;
      }
    }

    if( points > 0 )
      revert( "Not enough points" );
  }

  function mintTo(address[] calldata accounts, uint[] calldata quantity ) external payable onlyDelegates{
    require(quantity.length == accounts.length, "FoundersCoin: must provide equal quantities and accounts" );

    uint totalQuantity;
    unchecked{
      for(uint i; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
    }
    uint supply = totalSupply();
    require( supply + totalQuantity < MAX_SUPPLY, "FoundersCoin: mint/order exceeds supply" );

    unchecked{
      for(uint i; i < accounts.length; ++i){
        for(uint j; j < quantity[i]; ++j){
          _mint( accounts[i], tokens.length );
        }
      }
    }
  }

  function setActive(bool isMainsaleActive_) external onlyDelegates{
    isMainsaleActive = isMainsaleActive_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setMax(uint maxOrder_, uint maxSupply_, uint maxWallet_) external onlyDelegates{
    require( maxSupply_ >= totalSupply(), "FoundersCoin: specified supply is lower than current balance" );
    MAX_ORDER  = maxOrder_;
    MAX_SUPPLY = maxSupply_;
    MAX_WALLET = maxWallet_;
  }

  function setPrice( uint ethPrice ) external onlyDelegates{
    PRICE = ethPrice;
  }

  function addPayee( address account, uint shares ) external onlyOwner {
    _addPayee( account, shares );
  }

  function resetPayments() external onlyOwner{
    _resetCounters();
  }

  function setPayee( uint index, address account, uint newShares ) external onlyOwner {
    _setPayee( index, account, newShares );
  }

  //private
  function _mint( address to, uint tokenId ) private {
    _beforeTokenTransfer( address(0), to, tokenId );
    if( tokenId < 200 )
      tokens.push( Token( to, 2 ) );
    else
      tokens.push( Token( to, 1 ) );

    emit Transfer(address(0), to, tokenId);
  }
}
