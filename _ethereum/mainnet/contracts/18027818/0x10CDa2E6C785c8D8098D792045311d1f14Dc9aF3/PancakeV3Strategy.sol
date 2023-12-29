// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IERC20Metadata.sol";
import "./FullMath.sol";
import "./HarvestableApyFlowVault.sol";
import "./PancakeV3Library.sol";
import "./PricesLibrary.sol";
import "./Utils.sol";
import "./SafeAssetConverter.sol";
import "./BasePancakeV3Strategy.sol";

/// @author YLDR <admin@apyflow.com>
contract PancakeV3Strategy is BasePancakeV3Strategy {
    struct ConstructorParams {
        // BaseConcentratedLiquidityStrategy
        int24 ticksDown;
        int24 ticksUp;
        uint24 allowedPoolOracleDeviation;
        bool readdOnProfit;
        ChainlinkPriceFeedAggregator pricesOracle;
        IAssetConverter assetConverter;
        // BasePancakeV3Strategy
        IMasterChefV3 farm;
        uint256 pid;
        // ApyFlowVault
        IERC20Metadata asset;
        // ERC20
        string name;
        string symbol;
    }

    constructor(ConstructorParams memory params)
        BasePancakeV3Strategy(params.farm, params.pid)
        BaseConcentratedLiquidityStrategy(
            params.ticksDown,
            params.ticksUp,
            params.allowedPoolOracleDeviation,
            params.readdOnProfit,
            params.pricesOracle,
            params.assetConverter
        )
        ApyFlowVault(params.asset)
        ERC20(params.name, params.symbol)
    {
        BaseConcentratedLiquidityStrategy._performApprovals();
    }
}
