// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniversalLiquidator {
    event Swap(
        address indexed sellToken,
        address indexed buyToken,
        address indexed receiver,
        address initiator,
        uint256 sellAmount,
        uint256 minBuyAmount
    );

    function swap(address _sellToken, address _buyToken, uint256 _sellAmount, uint256 _minBuyAmount, address _receiver)
        external
        returns (uint256);
}
