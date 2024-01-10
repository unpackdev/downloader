// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./RariFuseStrategy.sol";

/// @title This strategy will deposit collateral token in a Rari Fuse Pool and earn interest.
contract RariFuseStrategyAPE is RariFuseStrategy {
    constructor(
        address _pool,
        address _swapManager,
        uint256 _fusePoolId,
        IFusePoolDirectory _fusePoolDirectory,
        string memory _name
    ) RariFuseStrategy(_pool, _swapManager, _fusePoolId, _fusePoolDirectory, _name) {
        oracleRouterIdx = 1;
    }
}
