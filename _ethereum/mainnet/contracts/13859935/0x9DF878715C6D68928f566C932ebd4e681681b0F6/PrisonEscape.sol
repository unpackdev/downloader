
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Strings.sol";
import "./ERC721Batch.sol";
import "./PaymentSplitterMod.sol";
import "./Signed.sol";

contract PrisonEscape is ERC721Batch, PaymentSplitterMod, Signed{
  using Address for address;
  using Strings for uint;

  uint public MAX_ORDER = 50;
  uint public MAX_SUPPLY = 10000;
  uint public MAX_WALLET = 10;
  uint public PRICE = 0.055 ether;

  bool public isMainsaleActive = false;
  bool public isPresaleActive = false;

  bool private _isSigned = true;
  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  address[] private _accounts = [
    0xAc16D248C981A3eFE1bB64ce7977a5c688590f99,
    0x39A29810e18F65FD59C43c8d2D20623C71f06fE1
  ];

  uint[] private _shares = [
    7364,
    2636
  ];

  constructor()
    Delegated()
    ERC721( "Prison Escape", "PE" )
    PaymentSplitterMod( _accounts, _shares ){
  }

  //view
  function tokensOfOwner( address account ) external view returns( Token[] memory ){
    Token[] memory tokens_ = new Token[]( _balances[ account ].length );
    for(uint i; i < _balances[ account ].length; ++i ){
      tokens_[i] = tokens[ _balances[ account ][i] ];
    }
    return tokens;
  }

  function tokenURI( uint tokenId ) external view override returns( string memory ){
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  //payable
  function mint( uint quantity, bytes calldata signature ) external payable{
    if( isMainsaleActive ){}
    else if( isPresaleActive ){
      if( _isSigned )
        require( _isAuthorized( quantity, signature ),  "Account not authorized" );

      require( _balances[ msg.sender ].length + quantity <= MAX_WALLET, "Don't be greedy" );
    }
    else{
      revert( "Public sale is not active" );
    }

    require( quantity <= MAX_ORDER,         "Order too big" );
    require( msg.value >= quantity * PRICE, "Not enough ETH sent" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Order exceeds supply" );
    for( uint i; i < quantity; ++i ){
      _mint( msg.sender, supply++ );
    }
  }


  //safety first
  fallback() external payable {}


  //delegated
  function burnFrom( address account, uint[] calldata tokenIds ) external payable onlyDelegates{
    _burned += tokenIds.length;
    for(uint i; i < tokenIds.length; ++i ){
      require( _exists( tokenIds[i] ), "PE: Burn request for nonexistent token" );
      require( ownerOf( tokenIds[i] ) == account, "PE: owner mismatch" );
      _burn( tokenIds[i] );
    }
  }

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

  function resurrect( address[] calldata accounts, uint[] calldata tokenIds ) external payable onlyDelegates{
    require(accounts.length == tokenIds.length, "PE: Must provide equal accounts and tokenIds" );
    require(_burned > tokenIds.length,          "PE: More tokenIds than burned tokens" );

    _burned -= tokenIds.length;
    for(uint i; i < tokenIds.length; ++i ){
      uint tokenId = tokenIds[i];
      require( !_exists( tokenId ), "PE: can't resurrect existing token" );

      address account = accounts[i];
      tokens[ tokenId ].owner = account;
      _balances[ account ].push( tokenId );
      _tokenApprovals[tokenId] = account;
      emit Transfer( address(0), account, tokenId );
    }
  }

  function setGuards( uint[] calldata tokenIds, bool isGuard ) external onlyDelegates{
    for(uint i; i < tokenIds.length; ++i ){
      require( _exists( tokenIds[i] ), "PE: cannot update nonexistent token" );
      tokens[ tokenIds[i] ].isGuard = isGuard;
    }
  }

  function setStaked( address account, uint[] calldata tokenIds, StakeType type_, uint32 time ) external onlyDelegates{
    if( time == 0 )
      time = uint32(block.timestamp);


    Token storage token;
    for(uint i; i < tokenIds.length; ++i ){
      require( _exists( tokenIds[i] ), "PE: cannot update nonexistent token" );

      token = tokens[ tokenIds[i] ];
      require( token.owner == account, "PE: owner mismatch" );
      token.isStaked = type_;
      token.stakeDate = time;
    }
  }

  function setTokens( uint[] calldata tokenIds, uint32 stakeDate, uint8 level, StakeType type_, bool isGuard ) external onlyDelegates{
    Token storage token;
    for(uint i; i < tokenIds.length; ++i ){
      require( _exists( tokenIds[i] ), "PE: cannot update nonexistent token" );

      token = tokens[ tokenIds[i] ];
      token.stakeDate = stakeDate;
      token.level = level;
      token.isStaked = type_;
      token.isGuard = isGuard;
    }
  }

  function setActive( bool presaleActive, bool mainsaleActive ) external onlyDelegates{
    isPresaleActive = presaleActive;
    isMainsaleActive = mainsaleActive;
  }

  function setMax( uint maxWallet, uint maxOrder, uint maxSupply ) external onlyDelegates{
    MAX_WALLET = maxWallet;
    MAX_ORDER = maxOrder;
    MAX_SUPPLY = maxSupply;
  }

  function setPrice( uint price ) external onlyDelegates{
    PRICE = price;
  }

  function setSigned( bool isSigned ) external onlyDelegates{
    _isSigned = isSigned;
  }

  function setUri( string calldata prefix, string calldata suffix ) external onlyDelegates{
    _tokenURIPrefix = prefix;
    _tokenURISuffix = suffix;
  }

  function withdraw() external {
    release( payable(0xAc16D248C981A3eFE1bB64ce7977a5c688590f99) );
    release( payable(0x39A29810e18F65FD59C43c8d2D20623C71f06fE1) );
  }


  //private
  function _isAuthorized( uint quantity, bytes calldata signature ) private view returns( bool ){
    address extracted = getSigner( createHash( quantity.toString() ), signature );
    return isAuthorizedSigner( extracted );
  }
}
