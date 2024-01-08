pragma solidity 0.8.2;

import "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapUsdcUsdtLp is PolygonStrategyQuickswapBase {
    // token0
    address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    // token1
    address public constant usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant usdcUsdtLpToken =
        0x2cF7252e74036d1Da831d11089D326296e64a728;
    address public constant usdcUsdtRewards =
        0x251d9837a13F38F3Fe629ce2304fa00710176222;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            usdc,
            usdt,
            usdcUsdtRewards,
            usdcUsdtLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapUsdcUsdtLp";
    }
}
