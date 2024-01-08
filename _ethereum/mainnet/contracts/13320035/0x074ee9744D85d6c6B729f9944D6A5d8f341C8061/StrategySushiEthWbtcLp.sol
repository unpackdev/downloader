// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiFarmBase.sol";

contract StrategySushiEthWbtcLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public constant sushi_wbtc_poolId = 21;
    // Token addresses
    address public constant sushi_eth_wbtc_lp = 0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58;
    address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiFarmBase(
            wbtc,
            sushi_wbtc_poolId,
            sushi_eth_wbtc_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthWbtcLp";
    }
}
