// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
interface IUniSwap {
	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function getAmountsOut(uint amountIn, address[] memory path) external returns (uint[] memory amounts);
}

interface IERC20 {
	function deposit() external payable;
	function balanceOf(address account) external view returns (uint256);
	function transfer(address to, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
}

contract CheckIt {
	address constant NICE_TOKEN = 0x53F64bE99Da00fec224EAf9f8ce2012149D2FC88;
	address constant WETH_TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address constant NICE_WETH_PAIR = 0x6D5416567E09b99D7B4b7897129Edb19C2F1305A;

    

	function test_transfer_tax() external payable returns(bool) {
        address[] memory buyPath = new address[](2);
        buyPath[0] = WETH_TOKEN;
        buyPath[1] = NICE_TOKEN;

         address[] memory sellPath = new address[](2);
        sellPath[0] = NICE_TOKEN;
        sellPath[1] = WETH_TOKEN;

        

		uint256[] memory buyExpected = IUniSwap(NICE_WETH_PAIR).getAmountsOut(msg.value, buyPath);
		IUniSwap(NICE_WETH_PAIR).swapExactETHForTokens{value: msg.value}(0, buyPath, address(this), block.timestamp + 15);
		uint256 buyReceived = IERC20(NICE_TOKEN).balanceOf(address(this));
		
		IERC20(NICE_TOKEN).approve(address(this), buyReceived);
		
		uint256[] memory sellExpected = IUniSwap(NICE_WETH_PAIR).getAmountsOut(buyReceived, sellPath);
		IUniSwap(NICE_WETH_PAIR).swapTokensForExactETH(0, buyReceived, sellPath, address(this), block.timestamp + 15);
		uint256 sellReceived = IERC20(WETH_TOKEN).balanceOf(address(this));
		
		return (buyExpected[1] > buyReceived || sellExpected[1] > sellReceived);
		
	}
}