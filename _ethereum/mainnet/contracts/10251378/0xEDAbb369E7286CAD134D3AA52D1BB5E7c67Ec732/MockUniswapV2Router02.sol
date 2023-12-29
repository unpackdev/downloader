pragma solidity ^0.6.0;

contract MockUniswapV2Router01 {
    struct SwapExactTokensForETH {
        uint amountIn;
        uint amountOutMin;
        address[] path;
        address to;
        uint deadline;
    }
    struct SwapExactETHForTokens {
        uint amountIn;
        uint amountOutMin;
        address[] path;
        address to;
        uint deadline;
    }
    SwapExactTokensForETH lastSwapExactTokensForETH;
    SwapExactETHForTokens lastSwapExactETHForTokens;

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts)
    {
        lastSwapExactTokensForETH = SwapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        amounts = new uint[](0);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline)
        public
        payable
        returns (uint[] memory amounts)
    {
        lastSwapExactETHForTokens = SwapExactETHForTokens(
            msg.value,
            amountOutMin,
            path,
            to,
            deadline
        );
        amounts = new uint[](2);
        amounts[0] = 0;
        amounts[1] = 0;
    }

    function getLastSwapExactTokensForETH() public view returns (
      uint,
      uint,
      address[] memory,
      address,
      uint) {
        return (
              lastSwapExactTokensForETH.amountIn,
              lastSwapExactTokensForETH.amountOutMin,
              lastSwapExactTokensForETH.path,
              lastSwapExactTokensForETH.to,
              lastSwapExactTokensForETH.deadline
        );
    }

    function getLastSwapExactETHForTokens() public view returns (
      uint,
      uint,
      address[] memory,
      address,
      uint
)
    {
      return (
            lastSwapExactETHForTokens.amountIn,
            lastSwapExactETHForTokens.amountOutMin,
            lastSwapExactETHForTokens.path,
            lastSwapExactETHForTokens.to,
            lastSwapExactETHForTokens.deadline
      );
    }
}
