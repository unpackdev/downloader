// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IERC20.sol";

import "./IPrimexDNS.sol";
import "./ITraderBalanceVault.sol";

interface ILiquidityMiningRewardDistributorStorage {
    struct LenderInfo {
        uint256 points;
        uint256 depositedAmount;
    }

    struct BucketInfo {
        uint256 totalPoints;
        uint256 totalPmxReward;
        uint256 withdrawnRewards;
        mapping(address => LenderInfo) lendersInfo;
    }

    function primexDNS() external view returns (IPrimexDNS);

    function pmx() external view returns (IERC20);

    function traderBalanceVault() external view returns (ITraderBalanceVault);

    function registry() external view returns (address);

    function reinvestmentRate() external view returns (uint256);

    function reinvestmentDuration() external view returns (uint256);

    function extraRewards(address, string calldata) external view returns (uint256);
}
