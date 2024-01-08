// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./RariFuseStrategy.sol";

// solhint-disable no-empty-blocks
/// @title Deposit DAI in a Rari Fuse Pool and earn interest.
contract RariFuseStrategyDAI is RariFuseStrategy {
    string public constant NAME = "RariFuse-Strategy-DAI";
    string public constant VERSION = "3.0.11";

    constructor(address _pool, address _swapManager)
        RariFuseStrategy(
            _pool,
            _swapManager,
            _cTokenByUnderlying(18, 0x6B175474E89094C44Da98b954EedeAC495271d0F) // Pool #18, DAI
        )
    {}
}
