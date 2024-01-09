// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Convex4MetaPoolStrategy.sol";

//solhint-disable no-empty-blocks
contract Convex4MetaPoolStrategyFRAXPool is Convex4MetaPoolStrategy {
    // FRAX-3CRV Metapool
    // Composed of [ FRAX , [ DAI, USDC, USDT ]]
    address internal constant METAPOOL = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    // Gauge for FRAX-3CRV Metapool
    address internal constant GAUGE = 0x72E158d38dbd50A483501c24f792bDAAA3e7D55C;
    // Convex Pool ID for FRAX-3CRV
    uint256 internal constant CONVEX_POOL_ID = 32;

    constructor(
        address _pool,
        address _swapManager,
        uint256 _collateralIdx,
        string memory _name
    ) Convex4MetaPoolStrategy(_pool, _swapManager, METAPOOL, GAUGE, _collateralIdx, CONVEX_POOL_ID, _name) {
        oracleRouterIdx = 1;
    }
}
