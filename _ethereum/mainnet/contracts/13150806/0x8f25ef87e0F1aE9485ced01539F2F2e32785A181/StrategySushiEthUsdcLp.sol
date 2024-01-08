// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiFarmBase.sol";

contract StrategySushiEthUsdcLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public constant sushi_usdc_poolId = 1;
    // Token addresses
    address public constant sushi_eth_usdc_lp =
        0x397FF1542f962076d0BFE58eA045FfA2d347ACa0;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiFarmBase(
            usdc,
            sushi_usdc_poolId,
            sushi_eth_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthUsdcLp";
    }
}
