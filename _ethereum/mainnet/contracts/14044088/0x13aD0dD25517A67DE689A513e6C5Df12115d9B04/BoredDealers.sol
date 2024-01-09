
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
import "./BD721Batch.sol";

contract BoredDealers is BD721Batch, PaymentSplitterMod, Signed {
  using Strings for uint256;

  uint public PRICE  = 0.08 ether;
  uint public MAX_ORDER  = 3;
  uint public MAX_SUPPLY = 10000;
  uint public MAX_WALLET = 3;

  uint public burned;
  bool public isPresaleActive = false;
  bool public isMainsaleActive = false;

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  address[] private addressList = [
    0xAB587eD25F72dA9fF2D9209f70CE1a086D100341,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];
  uint[] private shareList = [
    85,
    15
  ];

  constructor()
    BD721("Bored Dealers", "BD")
    PaymentSplitterMod(addressList, shareList){
  }


  //view: external
  fallback() external payable {}

  //view: IERC721Metadata
  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "BoredDealers: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  //view: IERC721Enumerable
  function totalSupply() public view override returns( uint totalSupply_ ){
    return tokens.length - burned;
  }


  //payable
  function mint( uint quantity, bytes calldata signature ) external payable {
    require( quantity <= MAX_ORDER,         "BoredDealers: order too big"             );
    require( msg.value >= PRICE * quantity, "BoredDealers: ether sent is not correct" );
    require( balances[ msg.sender ] + quantity <= MAX_WALLET, "BoredDealers: don't be greedy" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "BoredDealers: mint/order exceeds supply" );

    if( isMainsaleActive ){
      //ok
    }
    else if( isPresaleActive ){
      verifySignature( quantity.toString(), signature );
    }
    else{
      revert( "Sale is not active" );
    }

    unchecked{
      for(uint i; i < quantity; ++i){
        _mint( msg.sender, tokens.length );
      }
    }
  }


  //onlyDelegates
  function burnFrom( address account, uint[] calldata tokenIds ) external onlyDelegates{
    unchecked{
      for(uint i; i < tokenIds.length; ++i ){
        _burn( account, tokenIds[i] );
      }
    }
  }


  function mintTo(address[] calldata accounts, uint[] calldata quantity ) external payable onlyDelegates{
    require(quantity.length == accounts.length, "BoredDealers: must provide equal quantities and accounts" );

    uint totalQuantity;
    unchecked{
      for(uint i; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
    }
    uint supply = totalSupply();
    require( supply + totalQuantity < MAX_SUPPLY, "BoredDealers: mint/order exceeds supply" );

    unchecked{
      for(uint i; i < accounts.length; ++i){
        for(uint j; j < quantity[i]; ++j){
          _mint( accounts[i], tokens.length );
        }
      }
    }
  }

  function resurrect( address[] calldata accounts, uint[] calldata tokenIds ) external onlyDelegates{
    require(tokenIds.length == accounts.length,   "BoredDealers: must provide equal tokenIds and accounts" );

    unchecked{
      for(uint i; i < tokenIds.length; ++i ){
        _mint( accounts[i], tokenIds[i] );
      }
    }
  }


  function setActive(bool isPresaleActive_, bool isMainsaleActive_) external onlyDelegates{
    isPresaleActive = isPresaleActive_;
    isMainsaleActive = isMainsaleActive_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setMax(uint maxOrder, uint maxSupply, uint maxWallet) external onlyDelegates{
    require( maxSupply >= totalSupply(), "BoredDealers: specified supply is lower than current balance" );
    MAX_ORDER  = maxOrder;
    MAX_SUPPLY = maxSupply;
    MAX_WALLET = maxWallet;
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
  function _burn( address from, uint tokenId ) private {
    require( _exists( tokenId ), "BoredDealers: query for nonexistent token" );
    require( from == tokens[ tokenId ].owner, "BoredDealers: owner mismatch" );

    ++burned;
    _beforeTokenTransfer( from, address(0), tokenId );
    tokens[ tokenId ].owner = address(0);
    emit Transfer(from, address(0), tokenId);
  }

  function _mint( address to, uint tokenId ) private {
    _beforeTokenTransfer( address(0), to, tokenId );
    if( tokenId < tokens.length ){
      require( !_exists( tokenId ), "BoredDealers: can't resurrect existing token" );
      --burned;
      tokens[ tokenId ].owner = to;
    }
    else{
      tokens.push( Token( to ) );
    }

    emit Transfer(address(0), to, tokenId);
  }
}
