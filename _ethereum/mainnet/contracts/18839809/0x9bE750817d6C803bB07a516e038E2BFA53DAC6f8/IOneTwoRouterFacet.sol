// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibSwap.sol";
import "./StructInterface.sol";

interface IOneTwoRouterFacet is StructInterface{
    struct ConnextData {
        uint256 relayerFee;
        uint256 slippage;
        uint32 destDomainId;
        bool isFeeNative;
    }

    struct Swap {
        uint256 amount;
        uint256 minAmount;
        address weth;
        address partner;
    }

    function oneTwoSwap(
        address payable _receiver,
        uint256 _fromAmount,
        uint256 _minAmout,
        address _weth,
        address _partner,
        LibSwap.SwapData[] calldata _swaps
    ) external payable;

    function oneTwoQuote(
        address,
        uint256 _fromAmount,
        uint256 _minAmout,
        address _weth,
        address _partner,
        LibSwap.SwapData[] calldata _swaps
    ) external view returns(uint256);

    function swapAndBridgeTokensConnext(
        Swap calldata _swapData,
        ConnextData calldata _connextData, 
        BridgeData calldata _bridgeData,
        LibSwap.SwapData[] calldata _srcSwaps,
        bytes calldata _destSwaps
    ) 
        external 
        payable;

    function bridgeTokensConnext(
        uint256 _amount,
        address _partner,
        ConnextData calldata _connextData,
        BridgeData calldata _bridgeData,
        bytes calldata _destSwaps
    ) 
        external 
        payable;
}