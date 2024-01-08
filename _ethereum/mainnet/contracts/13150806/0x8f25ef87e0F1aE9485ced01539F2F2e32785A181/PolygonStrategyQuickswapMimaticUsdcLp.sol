pragma solidity 0.8.2;

import "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapMimaticUsdcLp is PolygonStrategyQuickswapBase {
    // token0
    address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    // token1
    address public constant miMatic =
        0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;
    address public constant miMaticUsdcLpToken =
        0x160532D2536175d65C03B97b0630A9802c274daD;
    address public constant miMaticUsdcRewards =
        0x1fdDd7F3A4c1f0e7494aa8B637B8003a64fdE21A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            usdc,
            miMatic,
            miMaticUsdcRewards,
            miMaticUsdcLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapMimaticUsdcLp";
    }
}
