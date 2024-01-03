// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IERC20Upgradeable.sol";

interface IRouter {
    struct TokenInput {
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        address bulk;
        address pendleSwap;
        ISwapAggregator.SwapData swapData;
    }

    struct TokenOutput {
        address tokenOut;
        uint256 minTokenOut;
        address tokenRedeemSy;
        address bulk;
        address pendleSwap;
        ISwapAggregator.SwapData swapData;
    }

    function addLiquiditySingleToken(
        address receiver,
        address market,
        uint256 minLpOut,
        IMarket.ApproxParams calldata guessPtReceivedFromSy,
        TokenInput calldata input
    )
        external
        payable
        returns (uint256 netLpOut, uint256 netSyFee);

    function removeLiquiditySingleToken(
        address receiver,
        address market,
        uint256 netLpToRemove,
        TokenOutput calldata output
    )
        external
        returns (uint256 netTokenOut, uint256 netSyFee);
}

interface ISwapAggregator {
    enum SwapType {
        NONE,
        KYBERSWAP,
        ONE_INCH,
        ETH_WETH
    }

    struct SwapData {
        SwapType swapType;
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }
}

interface IMarket is IERC20Upgradeable {
    struct ApproxParams {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffchain;
        uint256 maxIteration;
        uint256 eps;
    }

    function redeemRewards(address _user) external returns (uint256[] memory);

    function readTokens() external view returns (address sy, address pt, address yt);

    function userReward(address _token, address _user) external view returns (uint128 index, uint128 accrued);

    function getRewardTokens() external view returns (address[] memory);
}

interface ISyToken {
    enum AssetType {
        TOKEN,
        LIQUIDITY
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals);
}
