pragma solidity 0.8.2;

import "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapWbtcEthLp is PolygonStrategyQuickswapBase {
    // token0
    address public constant wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address public constant wbtcWethLpToken =
        0xdC9232E2Df177d7a12FdFf6EcBAb114E2231198D;

    address public constant wbtcWethRewards =
        0x070D182EB7E9C3972664C959CE58C5fC6219A7ad;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            wbtc,
            weth,
            wbtcWethRewards,
            wbtcWethLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapWbtcEthLp";
    }
}
