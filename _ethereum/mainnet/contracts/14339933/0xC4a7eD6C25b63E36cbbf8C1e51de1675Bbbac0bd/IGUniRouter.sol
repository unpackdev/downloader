pragma solidity >=0.5.0;

import "./IGUniPool.sol";

interface IGUniRouter {
    function addLiquidity(
        IGUniPool pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    ) external;

    function addLiquidityETH(
        IGUniPool pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        payable
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );
}
