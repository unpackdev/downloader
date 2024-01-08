// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiEthFarmDoubleRewardBase.sol";

contract StrategySushiDoubleEthAlcxLp is StrategySushiEthFarmDoubleRewardBase {
    uint256 public constant sushi_alcx_poolId = 0;

    address public constant sushi_eth_alcx_lp =
        0xC3f279090a47e80990Fe3a9c30d24Cb117EF91a8;
    address public constant alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiEthFarmDoubleRewardBase(
            sushi_alcx_poolId,
            sushi_eth_alcx_lp,
            alcx,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiDoubleEthAlcxLp";
    }
}
