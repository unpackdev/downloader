// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Convex4MetaPoolStrategy.sol";

//solhint-disable no-empty-blocks
contract Convex4MetaPoolStrategyIBBTCPool is Convex4MetaPoolStrategy {
    // ibbtc/sbtcCRV-f Metapool
    // Composed of [ ibBTC , [ renBTC, WBTC, SBTC ] ]
    address internal constant METAPOOL = 0xFbdCA68601f835b27790D98bbb8eC7f05FDEaA9B;
    // Gauge for FRAX-3CRV Metapool
    address internal constant GAUGE = 0x346C7BB1A7a6A30c8e81c14e90FC2f0FBddc54d8;
    // Convex Pool ID for ibbtc/sbtcCRV-f
    uint256 internal constant CONVEX_POOL_ID = 53;

    constructor(
        address _pool,
        address _swapManager,
        uint256 _collateralIdx,
        string memory _name
    ) Convex4MetaPoolStrategy(_pool, _swapManager, METAPOOL, GAUGE, _collateralIdx, CONVEX_POOL_ID, _name) {
        oracleRouterIdx = 1;
        // Curve sBTC DepositZap Contract
        DEPOSIT_ZAP = 0x7AbDBAf29929e7F8621B757D2a7c04d78d633834;
    }
}
