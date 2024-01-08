// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/* solhint-disable no-empty-blocks */

import "./AlphaLendStrategy.sol";

/// @title Deposit DPI in Alpha and earn interest.
contract AlphaLendStrategyDPI is AlphaLendStrategy {
    string public constant NAME = "Alpha-Lend-Strategy-DPI";
    string public constant VERSION = "3.0.21";

    // ibDPIv2 = 0xd80CE6816f263C3cA551558b2034B61bc9852b97
    constructor(address _pool, address _swapManager)
        AlphaLendStrategy(_pool, _swapManager, 0xd80CE6816f263C3cA551558b2034B61bc9852b97)
    {}
}
