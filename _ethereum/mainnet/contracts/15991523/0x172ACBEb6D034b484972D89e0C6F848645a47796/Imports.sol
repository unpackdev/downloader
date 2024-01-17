// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./DataTypes.sol";
import "./IAdapter.sol";
import "./IAdapterBorrow.sol";
import "./IAdapterInvestLimit.sol";
import "./IAdapterHarvestReward.sol";
import "./IAdapterStaking.sol";
import "./IAdapterStakingCurve.sol";
import "./IAdapterFull.sol";
import "./IWETH.sol";
import "./IYWETH.sol";
import "./IAaveV1PriceOracle.sol";
import "./IAaveV1LendingPoolAddressesProvider.sol";
import "./IAaveV1.sol";
import "./IAaveV1Token.sol";
import "./IAaveV1LendingPoolCore.sol";
import "./IAaveV2PriceOracle.sol";
import "./IAaveV2LendingPoolAddressesProvider.sol";
import "./IAaveV2LendingPoolAddressProviderRegistry.sol";
import "./IAaveV2.sol";
import "./IAaveV2Token.sol";
import "./IAaveV2ProtocolDataProvider.sol";
import "./ICompound.sol";
import "./IETHGateway.sol";
import "./ICream.sol";
import "./ICurveDeposit.sol";
import "./ICurveGauge.sol";
import "./ICurveAddressProvider.sol";
import "./ICurveSwap.sol";
import "./ICurveRegistry.sol";
import "./ITokenMinter.sol";
import "./IDForceDeposit.sol";
import "./IDForceStake.sol";
import "./IdYdX.sol";
import "./IFulcrum.sol";
import "./IHarvestController.sol";
import "./IHarvestDeposit.sol";
import "./IHarvestFarm.sol";
import "./ISushiswapMasterChef.sol";
import "./IYearn.sol";
import "./IYVault.sol";

contract Imports {
    /* solhint-disable no-empty-blocks */
    constructor() public {}
    /* solhint-disable no-empty-blocks */
}
