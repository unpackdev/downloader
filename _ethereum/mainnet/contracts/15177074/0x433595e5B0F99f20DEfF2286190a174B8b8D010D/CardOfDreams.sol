
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/************************
 * @author: squeebo_nft *
 * @team:   GoldenXnft  *
 ************************/

import "./ERC1155Base.sol";

contract CardOfDreams is ERC1155Base{
  enum TokenType {
    NONE,
    RWB,
    SILVER,
    GOLD
  }

  struct TypeSummary{
    uint mintPrice;
    uint balance;
    uint supply;
  }

  bool public IS_SALE_ACTIVE = false;

  mapping(TokenType => TypeSummary) public groups;

  constructor()
    ERC1155Base( "Card of Dreams", "CoD" ){

    setToken( 0, "Red",          "https://card-of-dreams.s3.amazonaws.com/access-pass/metadata/0.json", 2222, false, 1 ether, true, 0.025 ether );
    setToken( 1, "White",        "https://card-of-dreams.s3.amazonaws.com/access-pass/metadata/1.json", 2222, false, 1 ether, true, 0.025 ether );
    setToken( 2, "Blue",         "https://card-of-dreams.s3.amazonaws.com/access-pass/metadata/2.json", 2222, false, 1 ether, true, 0.025 ether );
    setToken( 3, "Silver",       "https://card-of-dreams.s3.amazonaws.com/access-pass/metadata/3.json", 2222, false, 1 ether, true, 0.075 ether );
    setToken( 4, "Gold",         "https://card-of-dreams.s3.amazonaws.com/access-pass/metadata/4.json", 1100, false, 1 ether, true, 0.125 ether );
    setToken( 5, "Green & Gold", "https://card-of-dreams.s3.amazonaws.com/access-pass/metadata/5.json",   12, false, 1 ether, true, 0.125 ether );

    groups[ TokenType.RWB    ] = TypeSummary( 0.025 ether, 0, 6000 );
    groups[ TokenType.SILVER ] = TypeSummary( 0.075 ether, 0, 2000 );
    groups[ TokenType.GOLD   ] = TypeSummary( 0.125 ether, 0, 1000 );
  }


  function withdraw() external onlyOwner{
    require(address(this).balance > 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }


  //view
  function getTokenSupply() external view returns( TypeSummary[] memory ){
    TypeSummary[] memory tokens_ = new TypeSummary[]( 6 );

    for( uint256 i = 0; i < 6; ++i ){
      tokens_[i] = TypeSummary( tokens[i].mintPrice, tokens[i].balance, tokens[i].supply );
    }

    return tokens_;
  }

  function getTypeSupply() external view returns( TypeSummary[] memory ){
    TypeSummary[] memory typesCopy = new TypeSummary[]( 4 );
    typesCopy[1] = groups[ TokenType.RWB ];
    typesCopy[2] = groups[ TokenType.SILVER ];
    typesCopy[3] = groups[ TokenType.GOLD ];
    return typesCopy;
  }


  //payable
  function mint( TokenType tokenType, uint256 quantity ) external payable{
    require( IS_SALE_ACTIVE, "sale is not active" );

    TypeSummary storage group = groups[ tokenType ];
    require( msg.value >= group.mintPrice * quantity, "Ether sent is not correct" );
    require( quantity <= group.supply - group.balance, "not enough supply" );
    group.balance += quantity;

    _mintRandom( _msgSender(), tokenType, quantity );
  }

  function mintTo( TokenType[] calldata tokenTypes, uint256[] calldata quantity, address[] calldata recipient ) external payable {
    require( IS_SALE_ACTIVE, "sale is not active" );
    require( tokenTypes.length == quantity.length, "unbalanced tokenId and quantity" );
    require( quantity.length == recipient.length, "unbalanced quantity and recipient" );

    uint256 totalValue = 0;
    for( uint256 i = 0; i < quantity.length; ++i ){
      TypeSummary storage group = groups[ tokenTypes[i] ];
      group.balance += quantity[i];
      totalValue = group.mintPrice * quantity[i];
    }
    require( msg.value >= totalValue, "Ether sent is not correct" );
    require( groups[ TokenType.RWB    ].balance <= groups[ TokenType.RWB    ].supply, "not enough RWB supply" );
    require( groups[ TokenType.SILVER ].balance <= groups[ TokenType.SILVER ].supply, "not enough SILVER supply" );
    require( groups[ TokenType.GOLD   ].balance <= groups[ TokenType.GOLD   ].supply, "not enough GOLD supply" );

    for( uint256 i = 0; i < quantity.length; ++i ){
      _mintRandom( recipient[i], tokenTypes[i], quantity[i] );
    }
  }

  //delegated
  function mintReserves( TokenType[] calldata tokenTypes, uint256[] calldata quantity, address[] calldata recipient ) external payable onlyDelegates {
    require( tokenTypes.length == quantity.length, "unbalanced tokenId and quantity" );
    require( quantity.length == recipient.length, "unbalanced quantity and recipient" );

    for( uint256 i = 0; i < quantity.length; ++i ){
      TypeSummary storage group = groups[ tokenTypes[i] ];
      group.balance += quantity[i];
    }
    require( groups[ TokenType.RWB    ].balance <= groups[ TokenType.RWB    ].supply, "not enough RWB supply" );
    require( groups[ TokenType.SILVER ].balance <= groups[ TokenType.SILVER ].supply, "not enough SILVER supply" );
    require( groups[ TokenType.GOLD   ].balance <= groups[ TokenType.GOLD   ].supply, "not enough GOLD supply" );

    for( uint256 i = 0; i < quantity.length; ++i ){
      _mintRandom( recipient[i], tokenTypes[i], quantity[i] );
    }
  }

  function setSaleActive( bool isActive ) external onlyDelegates{
    IS_SALE_ACTIVE = isActive;
  }

  function setSummary( TokenType tokenType, TypeSummary calldata typeSummary ) external onlyDelegates{
    require( 0 < uint(tokenType) && uint(tokenType) < 4, "invalid type" );

    TypeSummary storage group = groups[ tokenType ];
    require( typeSummary.supply >= group.balance, "specified supply is too low" );

    groups[ tokenType ].mintPrice = typeSummary.mintPrice;
    groups[ tokenType ].supply = typeSummary.supply;
  }


  //internal
  function _hashData() internal view returns( bytes memory ){
    //uint160 cbVal = uint160( address(block.coinbase) );
    bytes memory hashData = bytes.concat("", bytes20( address(block.coinbase)));  //160 bits

    //uint40 feeVal = uint40( block.basefee  % type(uint40).max );
    hashData = bytes.concat(hashData, bytes5( uint40( block.basefee  % type(uint40).max )));  //200 bits

    //uint32 limVal = uint32( block.gaslimit % type(uint32).max );
    hashData = bytes.concat(hashData, bytes4( uint32( block.gaslimit % type(uint32).max )));  //232 bits

    //uint40 gasVal =  uint40( tx.gasprice  % type(uint40).max );
    return bytes.concat(hashData, bytes5( uint40( tx.gasprice  % type(uint40).max )));  //272 bits
  }

  function _mintRandom( address to, TokenType tokenType, uint256 quantity ) internal {
    if( TokenType.RWB == tokenType ){
      bytes memory hashData = _hashData();
      for( uint16 i = 0; i < quantity; ++i ){
        uint256 tokenId = _randomToken( hashData, i, tokenType );
        _mint( to, tokenId, 1, "" );
      }
    }
    else if( TokenType.SILVER == tokenType ){
      _mint( to, 3, quantity, "" );
    }
    else if( TokenType.GOLD == tokenType ){
      bytes memory hashData = _hashData();
      for( uint16 i = 0; i < quantity; ++i ){
        uint256 tokenId = _randomToken( hashData, i, tokenType );
        _mint( to, tokenId, 1, "" );
      }
    }
    else{
      revert( "invalid token type" );
    }
  }

  function _randomToken( bytes memory hashData, uint16 index, TokenType tokenType ) internal view returns( uint256 ){
    if( TokenType.RWB == tokenType ){
      uint256 random = _random( hashData, index ) % 3;
      if( tokens[ random ].balance < tokens[ random ].supply )
        return random;

      random = random + 1 % 3;
      if( tokens[ random ].balance < tokens[ random ].supply )
        return random;

      return random + 1 % 3;
    }
    else if( TokenType.GOLD == tokenType ){
      if( tokens[ 5 ].balance < tokens[ 5 ].supply ){
        uint256 random = _random( hashData, index );
        if( random % 1000 < 11 && tokens[ 5 ].balance < tokens[ 5 ].supply )
          return 5;
        else
          return 4;
      }
      else{
        return 4;
      }
    }
    else{
      revert( "invalid token type" );
    }
  }

  function _random(bytes memory hashData, uint16 index) internal view returns( uint256 ){
    uint256 blkHash = uint256(blockhash( gasleft() % type(uint8).max ));
    return uint256(keccak256(
      index % 2 == 1 ?
        abi.encodePacked( blkHash, index, hashData ):
        abi.encodePacked( hashData, index, blkHash )
      ));
  }
}
