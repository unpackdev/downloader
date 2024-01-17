// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

struct MetaPath
{
	address router;
	address[] path;
}

interface IExofiCompatibleRouter
{
	function swapExactTokensForTokensSupportingFeeOnTransferTokens
	(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
	function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}

interface IArb is IOwnable
{
	function trade(MetaPath[] calldata metaPath, uint256 amount) external;
	function transferOtherERC20Token(IERC20 token, uint256 amount) external returns (bool);
	function getAmountOutMin(MetaPath[] calldata metaPath, uint256 amount) external view returns(uint256);
}

contract Arb is IArb, Ownable
{
	function trade(MetaPath[] calldata metaPath, uint256 amount) override external onlyOwner
	{
		uint256 startBalance = amount;
		uint256 intermediateTokenBalance = amount;
		for(uint256 i = 0; i < metaPath.length; ++i)
		{
			IERC20(metaPath[i].path[0]).approve(metaPath[i].router, intermediateTokenBalance);
			IExofiCompatibleRouter(metaPath[i].router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
				intermediateTokenBalance,
				1,
				metaPath[i].path,
				address(this),
				block.timestamp + 300 // solhint-disable-line not-rely-on-time
			);
			intermediateTokenBalance = IERC20(metaPath[i].path[metaPath[i].path.length - 1]).balanceOf(address(this));
		}
		require(intermediateTokenBalance > startBalance, "Trade Reverted, No Profit Made");
	}

	function transferOtherERC20Token(IERC20 token, uint256 amount) override external onlyOwner returns (bool)
	{
		return token.transfer(owner(), amount);
	}

	function getAmountOutMin(MetaPath[] calldata metaPath, uint256 amount) override external view returns(uint256)
	{
		uint256 amountOut = amount;
		for(uint256 i = 0; i < metaPath.length; ++i)
		{
			uint256[] memory amountOutMins = IExofiCompatibleRouter(metaPath[i].router).getAmountsOut(amountOut, metaPath[i].path);
			amountOut = amountOutMins[metaPath[i].path.length - 1];
		}
		return amountOut;
	}
}