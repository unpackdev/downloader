// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

interface IMedievalAccessControlCenter {
  function addressBook ( bytes32 ) external view returns ( address );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function getRoleMember ( bytes32 role, uint256 index ) external view returns ( address );
  function getRoleMemberCount ( bytes32 role ) external view returns ( uint256 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function setAddress ( bytes32 id, address _address ) external;
  function setRoleAdmin ( bytes32 role, bytes32 adminRole ) external;
  function treasury (  ) external view returns ( address );
  function dao (  ) external view returns ( address );
}
