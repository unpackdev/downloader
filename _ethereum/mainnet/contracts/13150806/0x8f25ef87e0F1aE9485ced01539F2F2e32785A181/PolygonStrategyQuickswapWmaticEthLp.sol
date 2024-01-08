pragma solidity 0.8.2;

import "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapWmaticEthLp is PolygonStrategyQuickswapBase {
    address public constant wmaticEthLpToken =
        0xadbF1854e5883eB8aa7BAf50705338739e558E5b;
    address public constant wmaticEthRewards =
        0x8FF56b5325446aAe6EfBf006a4C1D88e4935a914;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            wmatic,
            weth,
            wmaticEthRewards,
            wmaticEthLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapWmaticEthLp";
    }
}
