// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OpenSeaSharedStorefrontInterface {
  function balanceOf(address _owner, uint256 _id) external view returns (uint256){}
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory){}
}