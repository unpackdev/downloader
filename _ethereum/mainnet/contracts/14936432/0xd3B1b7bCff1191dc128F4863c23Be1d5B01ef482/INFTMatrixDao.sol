//SPDX-License-Identifier: MIT
/**
███    ███  █████  ████████ ██████  ██ ██   ██     ██████   █████   ██████  
████  ████ ██   ██    ██    ██   ██ ██  ██ ██      ██   ██ ██   ██ ██    ██ 
██ ████ ██ ███████    ██    ██████  ██   ███       ██   ██ ███████ ██    ██ 
██  ██  ██ ██   ██    ██    ██   ██ ██  ██ ██      ██   ██ ██   ██ ██    ██ 
██      ██ ██   ██    ██    ██   ██ ██ ██   ██     ██████  ██   ██  ██████  

Website: https://matrixdaoresearch.xyz/
Twitter: https://twitter.com/MatrixDAO_
 */
pragma solidity ^0.8.0;

interface INFTMatrixDao {
  function allowReveal (  ) external view returns ( bool );
  function approve ( address to, uint256 tokenId ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function devMint ( uint256 _amount, address _to ) external;
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function maxCollection (  ) external view returns ( uint256 );
  function mint ( uint32 _amount, uint32 _allowAmount, uint64 _expireTime, bytes memory _signature ) external;
  function name (  ) external view returns ( string memory );
  function numberMinted ( address _minter ) external view returns ( uint256 minted );
  function ownedTokens ( address _addr, uint256 _startId, uint256 _endId ) external view returns ( uint256[] memory tokenIds, uint256 endTokenId );
  function owner (  ) external view returns ( address );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function price (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function reveal ( uint256 _tokenId, bytes32 _hash, bytes memory _signature ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory _data ) external;
  function setAllowReveal ( bool _allowReveal ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setPrice ( uint256 _newPrice ) external;
  function setSigner ( address _newSigner ) external;
  function setUnrevealURI ( string memory _newURI ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function tokenReveal ( uint256 _tokenId ) external view returns ( bool isRevealed );
  function tokenURI ( uint256 _tokenId ) external view returns ( string memory uri );
  function totalMinted (  ) external view returns ( uint256 minted );
  function totalSupply (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferOwnership ( address newOwner ) external;
  function unrevealURI (  ) external view returns ( string memory );
  function withdraw ( address _to ) external;
}
