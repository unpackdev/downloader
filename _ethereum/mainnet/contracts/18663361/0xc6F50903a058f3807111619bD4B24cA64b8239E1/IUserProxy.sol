// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IUserProxy {
  function transferAssetToFyde(address _asset, uint256 _amount) external;

  function delegateVotingRights(address _delegate, address _asset) external;

  function setDelegate(bytes32 _id, address _delegate) external;

  function clearDelegate(bytes32 _id) external;
}
