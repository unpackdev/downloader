// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;
pragma abicoder v2;

import "./Ownable.sol";
import "./TransferHelper.sol";
import "./ISwapRouter.sol";

contract SwapForVolume is Ownable {
    // For the scope of these swap examples,
    // we will detail the design considerations when using
    // `exactInput`, `exactInputSingle`, `exactOutput`, and  `exactOutputSingle`.

    // It should be noted that for the sake of these examples, we purposefully pass in the swap router instead of inherit the swap router for simplicity.
    // More advanced example contracts will detail how to inherit the swap router safely.

    ISwapRouter public immutable swapRouter;

    // This example swaps DAI/WETH9 for single path swaps and DAI/USDC/WETH9 for multi path swaps.

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 100;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
    /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
    /// @return amountOut The amount of WETH9 received.
    function swapExactInputSingle(address _token1, address _token2, uint256 amountIn) public returns (uint256 amountOut) {
        IERC20(_token1).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _token1,
                tokenOut: _token2,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    function dualDexTrade(address _token1, address _token2, uint256 _amount) external onlyOwner {
	    uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
	    swapExactInputSingle(_token1, _token2, _amount);
	    uint token2Balance = IERC20(_token2).balanceOf(address(this));
	    uint tradeableAmount = token2Balance - token2InitialBalance;
	    swapExactInputSingle(_token2, _token1, tradeableAmount);
	  }

	  function getBalance (address _tokenContractAddress) external view  returns (uint256) {
			uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
			return balance;
		}
		
		function recoverEth() external onlyOwner {
			payable(msg.sender).transfer(address(this).balance);
		}

		function recoverTokens(address tokenAddress) external onlyOwner {
			IERC20 token = IERC20(tokenAddress);
			token.transfer(msg.sender, token.balanceOf(address(this)));
		}
}