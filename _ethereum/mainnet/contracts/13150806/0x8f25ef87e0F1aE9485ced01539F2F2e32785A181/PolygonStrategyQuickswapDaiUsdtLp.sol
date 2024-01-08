pragma solidity 0.8.2;

import "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapDaiUsdtLp is PolygonStrategyQuickswapBase {
    // token0
    address public constant dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    // token1
    address public constant usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant daiUsdtLpToken =
        0x59153f27eeFE07E5eCE4f9304EBBa1DA6F53CA88;
    address public constant daiUsdtRewards =
        0x97Efe8470727FeE250D7158e6f8F63bb4327c8A2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            usdt,
            dai,
            daiUsdtRewards,
            daiUsdtLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapDaiUsdtLp";
    }
}
