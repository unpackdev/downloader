// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiEthFarmDoubleRewardBase.sol";

contract StrategySushiDoubleEthCvxLp is StrategySushiEthFarmDoubleRewardBase {
    uint256 public constant sushi_cvx_poolId = 1;

    address public constant sushi_eth_cvx_lp =
        0x05767d9EF41dC40689678fFca0608878fb3dE906;
    address public constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiEthFarmDoubleRewardBase(
            sushi_cvx_poolId,
            sushi_eth_cvx_lp,
            cvx,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiDoubleEthCvxLp";
    }
}
