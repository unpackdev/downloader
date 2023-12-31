// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IWalletStore {
  function batchAddUser(address[] memory _users) external returns (bool);

  function replaceUser(address oldAddress, address newAddress) external returns (bool);

  function refer(address _referrer, address _referree) external returns (bool);

  function claimReward() external returns (bool);

  function addUser(address _address) external returns (bool);

  function setReferralReward(uint256 _referrerReward, uint256 _referreeReward)
    external
    returns (bool);

  function setToken(address _newToken) external returns (bool);

  function getVerifiedUsers() external view returns (address[] memory);

  function getReferrals(address _user) external view returns (address[] memory);

  function isVerified(address _user) external view returns (bool);

  function referreeReward() external view returns (uint256);

  function referrerReward() external view returns (uint256);

  function users(address)
    external
    view
    returns (
      bool isVerified,
      uint256 arrayIndex,
      uint256 lastAccessTime,
      address referrer,
      uint256 claimableAmount,
      uint256 totalClaimed
    );

  function waitTime() external view returns (uint256);
}
