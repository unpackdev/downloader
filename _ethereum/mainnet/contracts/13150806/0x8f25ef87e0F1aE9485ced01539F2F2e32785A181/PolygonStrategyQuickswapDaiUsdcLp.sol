pragma solidity 0.8.2;

import "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapDaiUsdcLp is PolygonStrategyQuickswapBase {
    // token0
    address public constant dai =0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    // token1
    address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant daiUsdcLpToken =
        0xf04adBF75cDFc5eD26eeA4bbbb991DB002036Bdd;
    address public constant daiUsdcRewards =
        0xEd8413eCEC87c3d4664975743c02DB3b574012a7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            usdc,
            dai,
            daiUsdcRewards,
            daiUsdcLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapDaiUsdcLp";
    }
}
