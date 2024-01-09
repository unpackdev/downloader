// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IHedge {
    function init(address _ammAddress) external;

    function underlying() external returns (address);

    function shortAsset() external returns (address);

    function buy(uint256 _underlyingAmount, uint256 _amountInMaximum) external returns (uint256 amountIn);

    function sell(uint256 _underlyingAmount, uint256 _amountOutMinimum) external returns (uint256 amountOut);

    function getShortPrice(uint256 _size) external view returns (uint256);

    function buyShort(uint256 _size, uint256 _amountToPay) external returns (uint256 amountIn);

    function sellShort(uint256 _size, uint256 amountToReceive) external returns (uint256 amountOut);

    function getValueQuote(int256 _position) external view returns (uint256);
}
