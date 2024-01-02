// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Structs.sol";

interface IRelayer {
  function getNumPendingRequest() external view returns (uint256);

  function getRequest(uint64 idx) external view returns (RequestData memory);

  function requestGovernanceWithdraw(
    UserRequest memory _userRequest,
    address _user,
    uint256 _maxTRSYToPay
  ) external payable;

  function requestWithdraw(UserRequest[] memory _userRequest, uint256 _maxTRSYToPay)
    external
    payable;

  function requestDeposit(
    UserRequest[] memory _userRequest,
    bool _keepGovRights,
    uint256 _minTRSYExpected
  ) external payable;

  function requestSwap(
    address _assetIn,
    uint256 _amountIn,
    address _assetOut,
    uint256 _minAmountOut
  ) external payable;

  function processRequests(uint256 _protocolAUM) external;

  function isQuarantined(address _asset) external view returns (bool);

  function isIncentiveManager(address _incentiveManager) external view returns (bool);

  function MAX_ASSET_TO_REQUEST() external view returns (uint8);

  function actionToGasUsage(bytes32 _actionHash) external view returns (uint256);

  function isUser(address _asset) external view returns (bool);

  function isAnyQuarantined(address[] memory _assets) external view returns (address);
}
