// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";
import "./IERC20.sol";
import "./IDerivative.sol";
import "./IPoolDeployment.sol";

interface SynthereumTICInterface is ISynthereumPoolDeployment {
  struct Fee {
    FixedPoint.Unsigned feePercentage;
    address[] feeRecipients;
    uint32[] feeProportions;
  }

  struct Roles {
    address admin;
    address maintainer;
    address liquidityProvider;
    address validator;
  }

  struct MintRequest {
    bytes32 mintID;
    uint256 timestamp;
    address sender;
    FixedPoint.Unsigned collateralAmount;
    FixedPoint.Unsigned numTokens;
  }

  struct ExchangeRequest {
    bytes32 exchangeID;
    uint256 timestamp;
    address sender;
    SynthereumTICInterface destTIC;
    FixedPoint.Unsigned numTokens;
    FixedPoint.Unsigned collateralAmount;
    FixedPoint.Unsigned destNumTokens;
  }

  struct RedeemRequest {
    bytes32 redeemID;
    uint256 timestamp;
    address sender;
    FixedPoint.Unsigned collateralAmount;
    FixedPoint.Unsigned numTokens;
  }

  function mintRequest(uint256 collateralAmount, uint256 numTokens) external;

  function approveMint(bytes32 mintID) external;

  function rejectMint(bytes32 mintID) external;

  function deposit(uint256 collateralAmount) external;

  function withdraw(uint256 collateralAmount) external;

  function exchangeMint(uint256 collateralAmount, uint256 numTokens) external;

  function depositIntoDerivative(uint256 collateralAmount) external;

  function withdrawRequest(uint256 collateralAmount) external;

  function withdrawPassedRequest() external;

  function redeemRequest(uint256 collateralAmount, uint256 numTokens) external;

  function approveRedeem(bytes32 redeemID) external;

  function rejectRedeem(bytes32 redeemID) external;

  function emergencyShutdown() external;

  function settleEmergencyShutdown() external;

  function exchangeRequest(
    SynthereumTICInterface destTIC,
    uint256 numTokens,
    uint256 collateralAmount,
    uint256 destNumTokens
  ) external;

  function approveExchange(bytes32 exchangeID) external;

  function rejectExchange(bytes32 exchangeID) external;

  function setFee(Fee calldata _fee) external;

  function setFeePercentage(uint256 _feePercentage) external;

  function setFeeRecipients(
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external;

  function derivative() external view returns (IDerivative);

  function calculateFee(uint256 collateralAmount)
    external
    view
    returns (uint256);

  function getMintRequests() external view returns (MintRequest[] memory);

  function getRedeemRequests() external view returns (RedeemRequest[] memory);

  function getExchangeRequests()
    external
    view
    returns (ExchangeRequest[] memory);
}
