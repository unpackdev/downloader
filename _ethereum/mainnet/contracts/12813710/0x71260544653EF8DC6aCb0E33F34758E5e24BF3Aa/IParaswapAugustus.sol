// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IParaswapAugustus {
    struct Route {
        address payable exchange;
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;
        Route[] routes;
    }

    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        Path[] path;
    }

    function multiSwap(SellData calldata) external payable returns (uint256);
}
