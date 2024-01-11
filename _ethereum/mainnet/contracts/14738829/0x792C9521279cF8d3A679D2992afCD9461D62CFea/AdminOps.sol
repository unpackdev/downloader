// SPDX-License-Identifier: ISC
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./PermissionManagement.sol";

/// @title Admin Operations Contract
/// @author hey@kumareth.com
/// @notice An ERC721 Inheritable contract that provides Admins the ability to have ultimate permissions over all the Tokens of this contract
/// @dev Monument Market Contract will use `marketTransfer` function to be able to transfer tokens without explicit approval.
abstract contract AdminOps is ERC721 {
  PermissionManagement private permissionManagement;

  constructor (
    address _permissionManagementContractAddress
  ) {
    permissionManagement = PermissionManagement(_permissionManagementContractAddress);
  }

  // all functions below this give permissions to the admins to have complete access to tokens in the project
  // its use is heavily discouraged in a decentralised ecosystem
  // it's recommended that all admins except the market contract give up their admin perms later down the road, or maybe delegate those powers to another transparent contract to ensure trust.

  // function intended to be used, only by the market contract  
  function marketTransfer(address _from, address _to, uint256 _tokenId) 
    public 
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _transfer(_from, _to, _tokenId);
    return _tokenId;
  }

  function godlyMint(address _to, uint256 _tokenId) 
    public
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _safeMint(_to, _tokenId);
    return _tokenId;
  }

  function godlyBurn(uint256 _tokenId) 
    public
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _burn(_tokenId);
    return _tokenId;
  }

  function godlyApprove(address _to, uint256 _tokenId) 
    public
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _approve(_to, _tokenId);
    return _tokenId;
  }

  function godlyApproveForAll(address _owner, address _operator, bool _shouldApprove) 
    public
    returns(address)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    _setApprovalForAll(_owner, _operator, _shouldApprove);
    return _owner;
  }
}
