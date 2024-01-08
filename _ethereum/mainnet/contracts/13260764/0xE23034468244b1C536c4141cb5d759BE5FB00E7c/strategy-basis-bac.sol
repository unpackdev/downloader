// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-basis-farm-base.sol";

contract StrategyBasisBac is StrategyBasisFarmBase {
    // Token addresses
    address public staking_pool = 0x190503cFbE97d77E83dedfC550C79EFd6E2E799f;
    address public bac = 0x3449FC1Cd036255BA1EB19d65fF4BA2b8903A69a;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock,
        address _redeem,
        address _burn,
        address _bond
    )
        public
        StrategyBasisFarmBase(
            bac,
            staking_pool,
            bac,
            _governance,
            _strategist,
            _controller,
            _timelock,
            _redeem,
            _burn,
            _bond
        )
    { }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyBasisBac";
    }
}
