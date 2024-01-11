// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

interface IpETH_Direct 
{


    function estimateBuy(uint256 piBNBAmountIn) external view returns (uint256 PiAmount);

    function estimateSell(uint256 PiAmountIn) external view returns (uint256 ethAmount);

    function easyBuy() external payable returns (uint256 PiAmount);
    function easyBuyFromPETH(uint256 piBNBIn) external  returns (uint256 PiAmount);

    function easySell(uint256 PiAmountIn) external returns (uint256 piBNBAmount);
    function easySellToPETH(uint256 PiAmountIn) external returns (uint256 piBNBAmount);

    function buyFromPETH(uint256 piBNBIn, uint256 dMagicOutMin) external returns (uint256 PiAmount);
    function buy(uint256 piBNBIn, uint256 dMagicOutMin) external payable returns (uint256 PiAmount);

    function sell(uint256 PiAmountIn, uint256 piBNBOutMin) external returns (uint256 piBNBAmount);
}
