// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./DigitalCertLib.sol";

interface IDigitalCert {
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function URI_SETTER_ROLE (  ) external view returns ( bytes32 );
  function balanceOf ( address account, uint256 id ) external view returns ( uint256 );
  function balanceOfBatch ( address[] memory accounts, uint256[] memory ids ) external view returns ( uint256[] memory );
  function burn ( address account, uint256 id, uint256 value ) external;
  function burnBatch ( address account, uint256[] memory ids, uint256[] memory values ) external;
  function createDigitalCert ( address account, uint256 amount, uint256 expire, uint256 price, bytes calldata data ) external;
  function createDigitalCertBatch ( address account, uint256[] calldata amounts, uint256[] calldata expires, uint256[] calldata prices, bytes calldata data ) external;
  function exists ( uint256 id ) external view returns ( bool );
  function getDigitalCertificate ( uint256 id, address marketAddress ) external view returns ( DigitalCertLib.DigitalCertificateRes memory );
  function getExpireDateById ( uint256 id ) external view returns ( uint256 );
  function getLastId (  ) external view returns ( uint256 );
  function getPriceById ( uint256 id ) external view returns ( uint256 );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function isApprovedForAll ( address account, address operator ) external view returns ( bool );
  function mint ( address account, uint256 id, uint256 amount, bytes memory data ) external;
  function mintBatch ( address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) external;
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function safeBatchTransferFrom ( address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) external;
  function safeTransferFrom ( address from, address to, uint256 id, uint256 amount, bytes memory data ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setExpireDate ( uint256 id, uint256 expire ) external;
  function setPrice ( uint256 id, uint256 price ) external;
  function setURI ( string memory newuri ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function totalSupply ( uint256 id ) external view returns ( uint256 );
  function uri ( uint256 ) external view returns ( string memory );
}
