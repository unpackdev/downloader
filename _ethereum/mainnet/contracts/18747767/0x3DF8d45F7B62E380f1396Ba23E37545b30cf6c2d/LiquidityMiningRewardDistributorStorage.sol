// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC165Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./Errors.sol";

import "./IWhiteBlackList.sol";
import "./ILiquidityMiningRewardDistributorStorage.sol";

contract LiquidityMiningRewardDistributorStorage is
    ILiquidityMiningRewardDistributorStorage,
    PausableUpgradeable,
    ERC165Upgradeable,
    ReentrancyGuardUpgradeable
{
    IPrimexDNS public override primexDNS;
    IERC20 public override pmx;
    ITraderBalanceVault public override traderBalanceVault;
    address public override registry;
    address public treasury;
    uint256 public override reinvestmentRate;
    uint256 public override reinvestmentDuration;
    mapping(address => mapping(string => uint256)) public override extraRewards;
    IWhiteBlackList internal whiteBlackList;
    // internal because we can't create getter for storage mapping inside structure
    // Mapping from bucket name => BucketInfo
    mapping(string => BucketInfo) internal buckets;
}
