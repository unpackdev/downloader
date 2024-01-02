// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IGovernanceModule {
  function fyde() external view returns (address);

  function proxyImplementation() external view returns (address);

  function proxyBalance(address proxy, address asset) external view returns (uint256);

  function strsyBalance(address _user, address _govToken) external view returns (uint256 balance);

  function assetToStrsy(address _asset) external view returns (address);

  function userToProxy(address _user) external view returns (address);

  function proxyToUser(address _proxy) external view returns (address);

  function isOnGovernanceWhitelist(address _asset) external view returns (bool);

  function getAllGovUsers() external view returns (address[] memory);

  function isAnyNotOnGovWhitelist(address[] calldata _assets) external view returns (address);

  function getUserGTAllowance(uint256 _TRSYAmount, address _token) external view returns (uint256);

  function govDeposit(
    address _depositor,
    address[] calldata _govToken,
    uint256[] calldata _amount,
    uint256[] calldata _amountTRSY,
    uint256 _totalTRSY
  ) external returns (address proxy);

  function govWithdraw(
    address _user,
    address _asset,
    uint256 _amountToWithdraw,
    uint256 _trsyToBurn
  ) external;

  function onStrsyTransfer(address sender, address _recipient) external;

  function unstakeGov(uint256 _amount, address _asset) external;

  function rebalanceProxy(address _proxy, address _asset, address[] memory _usersToRebalance)
    external;
}
