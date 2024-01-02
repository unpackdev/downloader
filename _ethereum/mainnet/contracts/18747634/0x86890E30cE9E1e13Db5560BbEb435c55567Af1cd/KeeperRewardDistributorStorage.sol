// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IAccessControl.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./PausableUpgradeable.sol";

import "./Errors.sol";

import "./IWhiteBlackList.sol";
import "./IKeeperRewardDistributorStorage.sol";

abstract contract KeeperRewardDistributorStorage is
    IKeeperRewardDistributorStorage,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC165Upgradeable
{
    address public override priceOracle;
    address public override registry;
    address public override pmx;
    address payable public override treasury;
    uint256 public override pmxPartInReward;
    uint256 public override nativePartInReward;
    uint256 public override positionSizeCoefficientA;
    int256 public override positionSizeCoefficientB;
    uint256 public override additionalGas;
    uint256 public override defaultMaxGasPrice;
    uint256 public override oracleGasPriceTolerance;
    PaymentModel public override paymentModel;
    mapping(address => KeeperBalance) public override keeperBalance;
    KeeperBalance public override totalBalance;
    mapping(KeeperActionType => KeeperActionRewardConfig) public override maxGasPerPosition;
    mapping(KeeperCallingMethod => DataLengthRestrictions) public override dataLengthRestrictions;
    mapping(DecreasingReason => uint256) public override decreasingGasByReason;
    IWhiteBlackList internal whiteBlackList;
}

abstract contract KeeperRewardDistributorStorageV2 is
    IKeeperRewardDistributorStorageV2,
    KeeperRewardDistributorStorage
{
    int256 public override minPositionSizeMultiplier;
}
