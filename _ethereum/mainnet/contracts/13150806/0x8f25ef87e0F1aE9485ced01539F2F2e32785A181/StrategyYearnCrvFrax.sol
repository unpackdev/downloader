// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategyYearnAffiliate.sol";

contract StrategyYearnCrvFrax is StrategyYearnAffiliate {
    // Token addresses
    address public constant crv_frax_lp = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address public constant yearn_registry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        StrategyYearnAffiliate(
            crv_frax_lp,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
}
