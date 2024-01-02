//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20Metadata.sol";
import "./DataTypes.sol";

interface IContangoOracle {

    function priceInNativeToken(PositionId positionId, IERC20 asset) external view returns (uint256 price_);

    function priceInNativeToken(MoneyMarketId mmId, IERC20 asset) external view returns (uint256 price_);

    function priceInUSD(PositionId positionId, IERC20 asset) external view returns (uint256 price_);

    function priceInUSD(MoneyMarketId mmId, IERC20 asset) external view returns (uint256 price_);

    function baseQuoteRate(PositionId positionId) external view returns (uint256);

}
