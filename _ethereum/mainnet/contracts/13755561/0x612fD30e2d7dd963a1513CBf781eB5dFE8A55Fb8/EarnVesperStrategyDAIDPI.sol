// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./EarnVesperStrategy.sol";

// solhint-disable no-empty-blocks
/// @title Deposit DAI in a Vesper Grow Pool and earn interest in DPI.
contract EarnVesperStrategyDAIDPI is EarnVesperStrategy {
    string public constant NAME = "Earn-Vesper-Strategy-DAI-DPI";
    string public constant VERSION = "3.0.22";

    // Strategy will deposit collateral in
    // vaDAI = 0x0538C8bAc84E95A9dF8aC10Aad17DbE81b9E36ee
    // And collect drip in
    // DPI = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b
    constructor(address _pool, address _swapManager)
        EarnVesperStrategy(
            _pool,
            _swapManager,
            0x0538C8bAc84E95A9dF8aC10Aad17DbE81b9E36ee,
            0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b
        )
    {}
}
