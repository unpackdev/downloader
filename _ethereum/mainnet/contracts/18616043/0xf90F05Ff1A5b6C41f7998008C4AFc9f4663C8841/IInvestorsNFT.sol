// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInvestorsNFT{
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function PAUSER_ROLE (  ) external view returns ( bytes32 );
  function READER_ROLE (  ) external view returns ( bytes32 );
  function REGISTRY (  ) external view returns ( address );
  function approve ( address to, uint256 tokenId ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function baseURI (  ) external view returns ( string memory );
  function burn ( uint256 tokenId ) external;
  function contractURI (  ) external view returns ( string memory );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function initialize ( string memory _erc721_name, string memory _erc721_symbol, address _registry ) external;
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function mintInvestmentNFT ( address to, uint8 tokenLevel ) external returns ( uint256 tokenId );
  function name (  ) external view returns ( string memory );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function pause (  ) external;
  function paused (  ) external view returns ( bool );
  function proxiableUUID (  ) external view returns ( bytes32 );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory data ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setBaseURI ( string memory newURI ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function tokenByIndex ( uint256 index ) external view returns ( uint256 );
  function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
  function tokenURI ( uint256 tokenId ) external view returns ( string memory );
  function totalSupply (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function unpause (  ) external;
  function updateRegistryAddress ( address newAddress ) external;
  function upgradeTo ( address newImplementation ) external;
  function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}
