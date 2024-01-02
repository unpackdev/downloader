pragma solidity 0.8.23;

import "./IUniswapV3DataProvider.sol";

interface IUniswapV3LeverageDataProvider {
    struct PositionData {
        IUniswapV3DataProvider.PositionData uniswapV3Position;
        address debtAsset;
        uint256 debt;
    }

    function getPositionData(address position) external view returns (PositionData memory);

    function getPositionsData(address[] memory positions) external view returns (PositionData[] memory datas);
}
