pragma solidity ^0.8.0;

// 0.8.0 support for Uni / Sushi V2
interface UniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts);
}
