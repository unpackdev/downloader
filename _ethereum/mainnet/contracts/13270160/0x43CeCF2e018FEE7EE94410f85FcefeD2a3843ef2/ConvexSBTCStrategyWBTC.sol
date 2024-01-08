// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ConvexStrategy.sol";
import "./console.sol";

interface IStableSwapV2 {
    function coins(int128 i) external view returns (address);
}

//solhint-disable no-empty-blocks
contract ConvexSBTCStrategyWBTC is ConvexStrategy {
    string public constant NAME = "Curve-Convex-sBTC-Strategy";
    string public constant VERSION = "3.0.14";
    address private constant THREEPOOL = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
    address private constant THREECRV = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    address private constant GAUGE = 0x705350c4BcD35c9441419DdD5d2f097d7a55410F;

    constructor(address _pool, address _swapManager)
        ConvexStrategy(_pool, THREEPOOL, THREECRV, GAUGE, _swapManager, 1, 7)
    {}

    function convertFrom18(uint256 amount) public pure override returns (uint256) {
        return amount / (10**10);
    }

    function _init(address _pool) internal virtual override {
        for (int128 _index = 0; _index < 3; _index++) {
            uint256 i = uint256(int256(_index));
            coins[i] = IStableSwapV2(_pool).coins(_index);
            coinDecimals[i] = IERC20Metadata(coins[i]).decimals();
        }
    }

    function _setupOracles() internal virtual override {
        swapManager.createOrUpdateOracle(CVX, WETH, oraclePeriod, 1);
        swapManager.createOrUpdateOracle(CRV, WETH, oraclePeriod, oracleRouterIdx);
        for (int128 i = 0; i < 3; i++) {
            swapManager.createOrUpdateOracle(IStableSwapV2(threePool).coins(i), WETH, oraclePeriod, oracleRouterIdx);
        }
    }
}
