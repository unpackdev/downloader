// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IERC20.sol";

interface IBalancerV2Pool {
    function getVault() external view returns (IVault);
    function getSwapFeePercentage() external view returns (uint256);
    function getNormalizedWeights() external view returns (uint256[] memory);
    function getPriceRateCache(IERC20 token)
        external
        view
        returns (
            uint256 rate,
            uint256 duration,
            uint256 expires
        );
}

interface IVault {
    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IERC20 assetIn;
        IERC20 assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}
