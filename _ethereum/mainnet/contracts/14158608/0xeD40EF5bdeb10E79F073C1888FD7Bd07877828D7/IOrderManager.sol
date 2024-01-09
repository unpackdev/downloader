// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.6;
pragma abicoder v2;

interface IOrderManager {

    struct LimitOrderParams {
        address _token0; 
        address _token1; 
        uint24 _fee;
        uint160 _sqrtPriceX96;
        uint128 _amount0;
        uint128 _amount1;
        uint256 _amount0Min;
        uint256 _amount1Min;
    }

    function placeLimitOrder(LimitOrderParams calldata params) external payable returns (uint256 tokenId);

    function processLimitOrder(
        uint256 _tokenId, uint256 _serviceFee, uint256 _monitorFee
    ) external returns (uint128, uint128);

    function canProcess(uint256 _tokenId, uint256 gasPrice) external returns (bool, uint256, uint256);

    function quoteKROM(uint256 weiAmount) external returns (uint256 quote);

    function funding(address owner) external view returns (uint256 balance);

    function feeAddress() external view returns (address);
}