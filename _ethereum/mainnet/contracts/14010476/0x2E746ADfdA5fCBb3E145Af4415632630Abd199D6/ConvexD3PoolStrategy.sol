// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ConvexStrategy.sol";

//solhint-disable no-empty-blocks
contract ConvexD3PoolStrategy is ConvexStrategy {
    address private constant THREEPOOL = 0xBaaa1F5DbA42C3389bDbc2c9D2dE134F5cD0Dc89;
    address private constant THREECRV = 0xBaaa1F5DbA42C3389bDbc2c9D2dE134F5cD0Dc89;
    address private constant GAUGE = 0x16C2beE6f55dAB7F494dBa643fF52ef2D47FBA36;
    // Convex Pool ID for D3 Pool
    uint256 internal constant CONVEX_POOL_ID = 58;
    // No. of pooled tokens in the Pool
    uint256 private constant N = 3;

    constructor(
        address _pool,
        address _swapManager,
        uint256 _collateralIdx,
        string memory _name
    ) ConvexStrategy(_pool, THREEPOOL, THREECRV, GAUGE, _swapManager, _collateralIdx, CONVEX_POOL_ID, N, _name) {}
}
