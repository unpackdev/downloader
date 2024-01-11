// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IAuctioneerLike {

    function getExpectedAmount(uint256 swapAmount_) external view returns (uint256 expectedAmount_);

}

interface IERC20Like {

    function allowance(address account_, address spender_) external view returns (uint256 allowance_);

    function approve(address account_, uint256 amount_) external;

    function balanceOf(address account_) external view returns (uint256 balance_);

    function decimals() external view returns (uint256 decimals_);

}

interface ILiquidatorLike {

    function getExpectedAmount(uint256 swapAmount_) external returns (uint256 expectedAmount_);

    function liquidatePortion(uint256 swapAmount_, uint256 maxReturnAmount_, bytes calldata data_) external;

}

interface IMapleGlobalsLike {

    function getLatestPrice(address asset_) external view returns (uint256 price_);

    function protocolPaused() external view returns (bool protocolPaused_);

}

interface IOracleLike {

    function latestRoundData() external view returns (
        uint80  roundId_,
        int256  answer_,
        uint256 startedAt_,
        uint256 updatedAt_,
        uint80  answeredInRound_
    );

}

interface IUniswapRouterLike {

    function swapExactTokensForTokens(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] calldata path_,
        address to_,
        uint256 deadline_
    ) external returns (uint256[] memory amounts_);

    function swapTokensForExactTokens(
        uint256 amountOut_,
        uint256 amountInMax_,
        address[] calldata path_,
        address to_,
        uint256 deadline_
    ) external returns (uint[] memory amounts_);

}
