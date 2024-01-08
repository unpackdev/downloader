// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiEthFarmDoubleRewardBase.sol";

contract StrategySushiDoubleEthPickleLp is StrategySushiEthFarmDoubleRewardBase {
    uint256 public constant sushi_pickle_poolId = 3;

    address public constant sushi_eth_pickle_lp =
        0x269Db91Fc3c7fCC275C2E6f22e5552504512811c;
    address public constant pickle = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiEthFarmDoubleRewardBase(
            sushi_pickle_poolId,
            sushi_eth_pickle_lp,
            pickle,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiDoubleEthPickleLp";
    }
}
