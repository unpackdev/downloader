// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ITradeModule{
    struct TradeInfo{
        string protocol;
        uint256 positionType;
        address sendAsset; 
        address receiveAsset;
        uint256 adapterType;  
        uint256 amountIn;
        uint256 amountLimit;
        uint256 approveAmount;
        bytes adapterData;  
    }
     event Trade(address _vault, TradeInfo[] _tradeInfos);
     function trade( address _vault, TradeInfo[] memory _tradeInfos) external;   
}