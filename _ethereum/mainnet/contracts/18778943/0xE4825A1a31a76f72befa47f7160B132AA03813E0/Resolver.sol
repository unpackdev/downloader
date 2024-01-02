//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IERC165.sol";
import "./IABIResolver.sol";
import "./IAddressResolver.sol";
import "./IAddrResolver.sol";
import "./IContentHashResolver.sol";
import "./IInterfaceResolver.sol";
import "./INameResolver.sol";
import "./IPubkeyResolver.sol";
import "./ITextResolver.sol";
import "./IExtendedResolver.sol";

interface Resolver is
  IERC165,
  IABIResolver,
  IAddressResolver,
  IAddrResolver,
  IContentHashResolver,
  IInterfaceResolver,
  INameResolver,
  IPubkeyResolver,
  ITextResolver,
  IExtendedResolver
{
  function setApprovalForAll(address, bool) external;

  function approve(bytes32 node, address delegate, bool approved) external;

  function isApprovedForAll(address account, address operator) external;

  function isApprovedFor(
    address owner,
    bytes32 node,
    address delegate
  ) external;

  function setABI(
    bytes32 node,
    uint256 contentType,
    bytes calldata data
  ) external;

  function setAddr(bytes32 node, address addr) external;

  function setAddr(bytes32 node, uint256 coinType, bytes calldata a) external;

  function setContenthash(bytes32 node, bytes calldata hash) external;

  function setName(bytes32 node, string calldata _name) external;

  function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;

  function setText(
    bytes32 node,
    string calldata key,
    string calldata value
  ) external;

  function setInterface(
    bytes32 node,
    bytes4 interfaceID,
    address implementer
  ) external;
}
