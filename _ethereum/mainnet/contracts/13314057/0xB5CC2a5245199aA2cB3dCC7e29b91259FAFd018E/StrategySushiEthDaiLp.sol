// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiFarmBase.sol";

contract StrategySushiEthDaiLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public constant sushi_dai_poolId = 2;
    // Token addresses
    address public constant sushi_eth_dai_lp =
        0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiFarmBase(
            dai,
            sushi_dai_poolId,
            sushi_eth_dai_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthDaiLp";
    }
}
