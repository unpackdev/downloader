// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;
import "./Utils.sol";

interface ITraderJoeV21Router {
    enum Version {
        V1,
        V2,
        V2_1
    }

    struct RouterPath {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        RouterPath memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        RouterPath memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);
}
