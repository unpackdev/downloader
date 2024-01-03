pragma experimental ABIEncoderV2;
pragma solidity ^0.6.10;

import "./Types.sol";

interface InterestRateModelInterface {
	function getSwapRate(
		int rateFactorPrev,
		bool userPayingFixed,
		uint orderNotional,
		uint lockedCollateralUnderlying,
		uint supplierLiquidityUnderlying
	) external view returns (uint rate, int rateFactorNew);
}

interface ERC20Interface {
    function transfer(address to, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external returns (uint);
}

interface CompInterface is ERC20Interface{
	function delegate(address delegatee) external;
}

interface CTokenInterface is ERC20Interface {
	function borrowIndex() external view returns (uint);
	function accrualBlockNumber() external view returns(uint);
	function borrowRatePerBlock() external view returns(uint);
	function exchangeRateStored() external view returns (uint);
}

abstract contract RhoInterface is Types {
	function supply(uint cTokenSupplyAmount) external virtual;
	function remove(uint removeCTokenAmount) external virtual;
	function openPayFixedSwap(uint notionalAmount, uint maximumFixedRateMantissa) external virtual returns (bytes32 swapHash);
	function openReceiveFixedSwap(uint notionalAmount, uint minFixedRateMantissa) external virtual returns (bytes32 swapHash);
	function close(
		bool userPayingFixed,
		uint benchmarkIndexInit,
		uint initBlock,
		uint swapFixedRateMantissa,
		uint notionalAmount,
		uint userCollateralCTokens,
		address owner
	) external virtual;

	event Supply(address indexed supplier, uint cTokenSupplyAmount, uint newSupplyAmount);
	event Remove(address indexed supplier, uint removeCTokenAmount, uint newSupplyValue);
	event OpenSwap(
		bytes32 indexed swapHash,
		bool userPayingFixed,
		uint benchmarkIndexInit,
		uint initBlock,
		uint swapFixedRateMantissa,
		uint notionalAmount,
		uint userCollateralCTokens,
		address indexed owner
	);
	event CloseSwap(
		bytes32 indexed swapHash,
		address indexed owner,
		uint userPayout,
		uint penalty,
		uint benchmarkIndexFinal
	);
	event Accrue(uint supplierLiquidityNew, uint lockedCollateralNew);
	event SetInterestRateModel(address newModel, address oldModel);
	event SetPause(bool isPaused);
	event AdminRenounced();
	event CompTransferred(address dest, uint amount);
	event CompDelegated(address delegatee);
	event SetCollateralRequirements(uint minFloatRateMantissa, uint maxFloatRateMantissa);
	event AdminChanged(address oldAdmin, address newAdmin);
	event SetLiquidityLimit(uint limit);

	InterestRateModelInterface public interestRateModel;

	uint public lastAccrualBlock;
	Exp public benchmarkIndexStored;

	/* Notional size of each leg, one adjusting for compounding and one static */
	uint public notionalReceivingFixed;
	uint public notionalPayingFloat;

	uint public notionalPayingFixed;
	uint public notionalReceivingFloat;

	/* Measure of outstanding swap obligations. 1 Unit = 1e18 notional * 1 block. Used to calculate collateral requirements */
	int public parBlocksReceivingFixed;
	int public parBlocksPayingFixed;

	/* Per block fixed / float interest rates used in collateral calculations */
	Exp public avgFixedRateReceiving;
	Exp public avgFixedRatePaying;

	/* Per block float rate bounds used in collateral calculations */
	Exp public maxFloatRate;
	Exp public minFloatRate;

	/* Protocol PnL */
	uint public supplyIndex;
	CTokenAmount public supplierLiquidity;

	int public rateFactor;// for interest rate model

	address public admin;

	/* Pausing safety functions that can pause open and supply functions */
	bool public isPaused;
	CTokenAmount public liquidityLimit;

	mapping(address => SupplyAccount) public supplyAccounts;
	mapping(bytes32 => bool) public swaps;

	struct SupplyAccount {
		CTokenAmount amount;
		uint lastBlock;
		uint index;
	}

	struct Swap {
		bool userPayingFixed;
		uint notionalAmount;
		uint swapFixedRateMantissa;
		uint benchmarkIndexInit;
		uint userCollateralCTokens;
		uint initBlock;
		address owner;
	}

}
