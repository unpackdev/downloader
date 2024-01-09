
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC165.sol";

contract DWFProxy is Ownable, IERC165, IERC721Enumerable, IERC721Metadata {
  address public source = 0x5B42A2eb3b141ee3cfb6Bcc4484E68c7Fdf259Ef;

  //IERC165
  function supportsInterface(bytes4 interfaceId) public pure override returns( bool isSupported ){
    return 
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId;
  }


  //IERC721
  function balanceOf(address owner) external view override returns( uint256 balance ){
    uint supply = IERC721Enumerable( source ).totalSupply();
    for(uint i; i < supply; ++i ){
      if( IERC721( source ).ownerOf( i ) == owner )
        ++balance;
    }
    return balance;
  }

  function getApproved( uint256 tokenId ) external view override returns( address operator ){
    return IERC721( source ).getApproved( tokenId );
  }

  function isApprovedForAll( address owner, address operator ) external view override returns( bool ){
    return IERC721( source ).isApprovedForAll( owner, operator );
  }

  function ownerOf(uint256 tokenId) external view override returns(address owner){
    return IERC721( source ).ownerOf( tokenId );
  }

  function approve(address to, uint256 tokenId) pure external override{
    revert( "approve: not implemented, this proxy is read-only" );
  }

  function safeTransferFrom( address from, address to, uint256 tokenId ) pure external override{
    revert( "safeTransferFrom: not implemented, this proxy is read-only" );
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) pure external override{
    revert( "safeTransferFrom: not implemented, this proxy is read-only" );
  }

  function setApprovalForAll(address operator, bool _approved) pure external override{
    revert( "setApprovalForAll: not implemented, this proxy is read-only" );
  }

  function transferFrom( address from, address to, uint256 tokenId ) pure external override{
    revert( "transferFrom: not implemented, this proxy is read-only" );
  }


  //IERC721Enumerable
  function totalSupply() external view override returns( uint256 supply ){
    return IERC721Enumerable( source ).totalSupply();
  }

  function tokenOfOwnerByIndex( address owner, uint256 index ) external view override returns( uint256 tokenId ){
   return IERC721Enumerable( source ).tokenOfOwnerByIndex( owner, index );
  }

  function tokenByIndex( uint256 index ) external view override returns( uint256 tokenId ){
   return IERC721Enumerable( source ).tokenByIndex( index );
  }

  function setSource( address source_ ) external onlyOwner {
    source = source_;
  }


  //IERC721Metadata
  function name() external view override returns ( string memory ){
    return IERC721Metadata( source ).name();
  }

  function symbol() external view override returns( string memory ){
    return IERC721Metadata( source ).symbol();
  }

  function tokenURI( uint256 tokenId ) external view override returns( string memory ){
    return IERC721Metadata( source ).tokenURI( tokenId );
  }
}
