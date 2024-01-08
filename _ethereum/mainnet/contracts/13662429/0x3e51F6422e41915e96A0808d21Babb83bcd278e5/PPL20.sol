
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Delegated.sol";
import "./ERC20.sol";
import "./Address.sol";

interface IERC721{
  function ownerOf( uint tokenId ) external view returns( address );
}

contract PPL20 is ERC20, Delegated {
  using Address for address;

  mapping(address =>
    mapping(uint => uint)) private _tokenBalances;

  constructor()
    ERC20( "Pineapple", "PPL" )
    Delegated(){
  }

  //external
  fallback() external payable {}

  receive() external payable {}

  function balanceOfToken(address tokenContract, uint tokenId) external view returns (uint) {
    return _tokenBalances[tokenContract][tokenId];
  }

  function transferAccount2Token( address tokenContract, uint tokenId, uint pineapples ) external {
    require( _contracts[tokenContract], "PPL20: tokenContract must be a contract address" );
    _transfer( _msgSender(), tokenContract, pineapples);
    _tokenBalances[tokenContract][tokenId] += pineapples;
  }

  function transferTokens2Account( address[] calldata tokenContracts, uint[] calldata tokenIds, address recipient ) external {
    require( tokenContracts.length == tokenIds.length,  "PPL20: must provide equal contracts and tokens" );

    uint pineapples;
    uint tokenId;
    address tokenContract;
    for( uint i; i < tokenContracts.length; ++i ){
      tokenId = tokenIds[i];
      tokenContract = tokenContracts[i];
      require( _contracts[tokenContract], "PPL20: tokenContract must be a contract address" );
      require( IERC721( tokenContract ).ownerOf( tokenId ) == _msgSender(), "PPL20: not authorized" );

      pineapples = _tokenBalances[tokenContract][tokenId];
      if( pineapples > 0 ){
        _tokenBalances[tokenContract][tokenId] = 0;
        _transfer(tokenContract, recipient, pineapples);
      }
    }
  }


  //delegated
  function burnFromAccount( address account, uint pineapples ) external onlyDelegates{
    _burn( account, pineapples );
  }

  function burnFromTokens( address[] calldata tokenContracts, uint[] calldata tokenIds, uint pineapples ) external onlyDelegates{
    require( tokenContracts.length == tokenIds.length,  "PPL20: must provide equal contracts and tokens" );

    uint remainder = pineapples;
    for( uint i; i < tokenContracts.length; ++i ){
      require( _contracts[tokenContracts[i]], "PPL20: tokenContract must be a contract address" );

      uint tokenBalance = _tokenBalances[tokenContracts[i]][tokenIds[i]];
      uint used = remainder < tokenBalance ? remainder : tokenBalance;
      _tokenBalances[tokenContracts[i]][tokenIds[i]] -= used;
      _burn( tokenContracts[i], used );
      remainder -= used;
    }

    require(remainder == 0, "PPL20: burn amount exceeds balance");
  }

  function mintToAccount( address account, uint pineapples ) external onlyDelegates{
    _mint( account, pineapples );
  }

  function mintToTokens( address[] calldata tokenContracts, uint[] calldata tokenIds, uint[] calldata pineapples ) external onlyDelegates{
    require( tokenContracts.length == tokenIds.length,  "Must provide equal quantities of contracts and tokens" );
    require( tokenIds.length == pineapples.length,  "Must provide equal quantities of tokens and pineapples" );

    for( uint i; i < tokenContracts.length; ++i ){
      if( pineapples[i] > 0 ){
        if( tokenContracts[i].isContract() && !_contracts[tokenContracts[i]] ){
          //25000
          _contracts[tokenContracts[i]] = true;
        }

        //25000
        _mint( tokenContracts[i], pineapples[i] );

        //25000 x tokenContracts.length
        _tokenBalances[ tokenContracts[i] ][ tokenIds[i] ] += pineapples[i];
      }
    }
  }
}
