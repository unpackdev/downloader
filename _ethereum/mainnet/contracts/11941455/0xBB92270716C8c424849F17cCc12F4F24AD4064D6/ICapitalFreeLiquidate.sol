pragma solidity >=0.5.0;

interface ICapitalFreeLiquidate {
	function factory() external pure returns (address);
	function bDeployer() external pure returns (address);
	function cDeployer() external pure returns (address);
	function WETH() external pure returns (address);
	
	function to() external pure returns (address);
	
	function liquidate(
		address uniswapV2Pair,
		uint8 toLiquidateIndex,
		uint8 takeProfitIndex,
		address borrower,
		uint liquidateAmountMax,
		uint profitMin
	) external returns (uint profit);
	
	function skim(address token) external;
	
	function getBorrowable(address uniswapV2Pair, uint8 index) external view returns (address borrowable);
	function getCollateral(address uniswapV2Pair) external view returns (address collateral);
	function getLendingPool(address uniswapV2Pair) external view returns (address collateral, address borrowableA, address borrowableB);
}