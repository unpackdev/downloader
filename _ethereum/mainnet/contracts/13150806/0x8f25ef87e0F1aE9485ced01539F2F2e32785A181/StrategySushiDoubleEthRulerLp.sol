// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiEthFarmDoubleRewardBase.sol";

contract StrategySushiDoubleEthRulerLp is StrategySushiEthFarmDoubleRewardBase {
    uint256 public constant sushi_ruler_poolId = 7;

    address public constant sushi_eth_ruler_lp =
        0xb1EECFea192907fC4bF9c4CE99aC07186075FC51;
    address public constant ruler = 0x2aECCB42482cc64E087b6D2e5Da39f5A7A7001f8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiEthFarmDoubleRewardBase(
            sushi_ruler_poolId,
            sushi_eth_ruler_lp,
            ruler,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiDoubleEthRulerLp";
    }
}
