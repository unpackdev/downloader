// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVesperPool.sol";
import "./Strategy.sol";
import "./Crv3x.sol";
import "./Crv3PoolStrategyBase.sol";

interface IStableSwapV2 {
    function coins(int128 i) external view returns (address);
}

/// @title This strategy will deposit collateral token in Curve 3Pool and earn interest.
abstract contract CrvsBTCPoolStrategy is Crv3PoolStrategyBase {
    address private constant THREEPOOL = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
    address private constant THREECRV = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    address private constant GAUGE = 0x705350c4BcD35c9441419DdD5d2f097d7a55410F;

    constructor(
        address _pool,
        address _swapManager,
        uint256 _collateralIdx
    ) Crv3PoolStrategyBase(_pool, THREEPOOL, THREECRV, GAUGE, _swapManager, _collateralIdx) {
        require(
            IStableSwapV2(THREEPOOL).coins(int128(uint128(_collateralIdx))) == address(IVesperPool(_pool).token()),
            "collateral-mismatch"
        );
    }

    function _init(address _pool) internal virtual override {
        for (int128 _index = 0; _index < 3; _index++) {
            uint256 i = uint256(int256(_index));
            coins[i] = IStableSwapV2(_pool).coins(_index);
            coinDecimals[i] = IERC20Metadata(coins[i]).decimals();
        }
    }

    function _setupOracles() internal virtual override {
        swapManager.createOrUpdateOracle(CRV, WETH, oraclePeriod, oracleRouterIdx);
        for (int128 i = 0; i < 3; i++) {
            swapManager.createOrUpdateOracle(IStableSwapV2(threePool).coins(i), WETH, oraclePeriod, oracleRouterIdx);
        }
    }
}
