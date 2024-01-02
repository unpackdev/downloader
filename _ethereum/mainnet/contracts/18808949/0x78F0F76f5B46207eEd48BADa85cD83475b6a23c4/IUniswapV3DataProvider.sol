pragma solidity 0.8.23;

interface IUniswapV3DataProvider {
    struct PositionData {
        uint256 tokenId;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0;
        uint256 amount1;
        uint256 fee0;
        uint256 fee1;
        uint128 liquidity;
    }

    function getPositionData(uint256 tokenId) external view returns (PositionData memory);

    function getPositionsData(uint256[] memory tokenIds) external view returns (PositionData[] memory datas);
}
