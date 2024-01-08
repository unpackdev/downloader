// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAuthToken {
  function initialize(
    string memory _name,
    string memory _symbol,
    uint256 _tokenId
  ) external;

  function transferOwnership(address _from, address _to) external;

  function hasRole(bytes32 role, address account) external view returns (bool);
}
