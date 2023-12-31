// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

import "./AccessControl.sol";

import "./ICurve.sol";
import "./AggregatorInterface.sol";
import "./IMinter.sol";

contract LiquidatePool is AccessControl {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	bytes32 public constant POOL_MANAGER_ROLE = keccak256("POOL_MANAGER_ROLE");

	// used to redeem stbt
	address public mxpRedeemPool;
	address public stbtMinter;

	address public admin;
	// ustpool
	address public ustpool;
	// stbt address
	IERC20 public stbt;
	// usdc address
	IERC20 public usdc;
	// STBT curve pool
	// Mainnet: 0x892D701d94a43bDBCB5eA28891DaCA2Fa22A690b
	ICurve curvePool;

	// Used to calculate the fee base.
	uint256 public constant FEE_COEFFICIENT = 1e8;
	// Max fee rates can't over then 1%
	uint256 public constant maxLiquidateFeeRate = FEE_COEFFICIENT / 100;
	uint256 public constant maxLiquidateMXPFeeRate = FEE_COEFFICIENT / 100;
	// liquidateFeeRate: 0.1% => 100000 (10 ** 5)
	// liquidateFeeRate: 10% => 10000000 (10 ** 7)
	// liquidateFeeRate: 100% => 100000000 (10 ** 8)
	// It's used when call liquidate method.
	uint256 public liquidateFeeRate;
	uint256 public liquidateMXPFeeRate;
	// Fee Collector, used to receive fee.
	address public feeCollector;

	// liquidation index.
	uint256 public liquidationIndex;
	// the time for liquidation.
	uint256 public processPeriod;

	// redemption option
	bool public isOTC = false;

	struct LiquidationDetail {
		uint256 id;
		uint256 timestamp;
		address user;
		uint256 repayAmount;
		uint256 receiveAmountAfterFee;
		uint256 MXPFee;
		uint256 protocolFee;
		// False not withdraw, or True.
		bool isDone;
	}

	// Mapping from liquidation index to liquidationDetail.
	mapping(uint256 => LiquidationDetail) public liquidationDetails;

	// mint threshold for underlying token
	uint256 public mintThreshold;
	// redeem threshold for STBT
	uint256 public redeemThreshold;
	// target price
	int256 public lowerPrice;
	int256 public upperPrice;
	// priceFeed be using check USDC is pegged
	AggregatorInterface public priceFeed;
	// coins , [DAI, USDC, USDT]
	// see https://etherscan.io/address/0x892D701d94a43bDBCB5eA28891DaCA2Fa22A690b#code
	address[3] public coins;

	event liquidateRequested(
		uint256 id,
		uint256 timestamp,
		address indexed user,
		uint256 repayAmount,
		uint256 underlyingAmount,
		uint256 receiveAmountAfterFee,
		uint256 MXPFee,
		uint256 protocolFee
	);
	event FinalizeLiquidation(
		address indexed user,
		uint256 amount,
		uint256 protocolFee,
		uint256 id
	);

	event ProcessPeriodChanged(uint256 newProcessPeriod);
	event FeeCollectorChanged(address newFeeCollector);
	event LiquidateFeeRateChanged(uint256 newLiquidateFeeRate);
	event RedeemMXPFeeRateChanged(uint256 newRedeemMXPFeeRate);
	event RedeemPoolChanged(address newRedeemPool);
	event RedeemMinterChanged(address newRedeemMinter);
	event CurvePoolChanged(address newCurvePool);
	event RedeemThresholdChanged(uint256 newRedeemThreshold);
	event PegPriceChanged(int256 lowerPrice, int256 upperPrice);
	event RedemptionOptionChanged(bool isOTC);

	constructor(
		address _admin,
		address _ustpool,
		address _mxpRedeemPool,
		address _stbt,
		address _usdc,
		address _priceFeed,
		address[3] memory _coins
	) {
		require(_admin != address(0), "!_admin");
		require(_ustpool != address(0), "!_ustpool");
		require(_mxpRedeemPool != address(0), "!_mxpRedeemPool");
		require(_stbt != address(0), "!_stbt");
		require(_usdc != address(0), "!_usdc");
		require(_priceFeed != address(0), "!_priceFeed");

		admin = _admin;
		ustpool = _ustpool;
		mxpRedeemPool = _mxpRedeemPool;
		stbt = IERC20(_stbt);
		usdc = IERC20(_usdc);
		priceFeed = AggregatorInterface(_priceFeed);
		coins = _coins;

		_setRoleAdmin(POOL_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
		_setupRole(POOL_MANAGER_ROLE, admin);
	}

	/**
	 * @dev to set the period of processing
	 * @param _processPeriod the period of processing. it's second.
	 */
	function setProcessPeriod(uint256 _processPeriod) external onlyRole(POOL_MANAGER_ROLE) {
		require(_processPeriod <= 7 days, "should be less than 7 days");
		processPeriod = _processPeriod;
		emit ProcessPeriodChanged(processPeriod);
	}

	/**
	 * @dev to set the collector of fee
	 * @param _feeCollector the address of collector
	 */
	function setFeeCollector(address _feeCollector) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_feeCollector != address(0), "!_feeCollector");
		feeCollector = _feeCollector;
		emit FeeCollectorChanged(feeCollector);
	}

	/**
	 * @dev to set the rate of liquidate fee
	 * @param _liquidateFeeRate the rate. it should be multiply 10**6
	 */
	function setLiquidateFeeRate(uint256 _liquidateFeeRate) external onlyRole(POOL_MANAGER_ROLE) {
		require(
			_liquidateFeeRate <= maxLiquidateFeeRate,
			"Liquidate fee rate should be less than 1%."
		);
		liquidateFeeRate = _liquidateFeeRate;
		emit LiquidateFeeRateChanged(liquidateFeeRate);
	}

	/**
	 * @dev to set the redemption option
	 * @param _isOTC option
	 */
	function setRedemptionOption(bool _isOTC) external onlyRole(POOL_MANAGER_ROLE) {
		isOTC = _isOTC;
		emit RedemptionOptionChanged(isOTC);
	}

	/**
	 * @dev to set the rate of MP redeem fee
	 * @param _liquidateMXPFeeRate the rate. it should be multiply 10**6
	 */
	function setRedeemMXPFeeRate(
		uint256 _liquidateMXPFeeRate
	) external onlyRole(POOL_MANAGER_ROLE) {
		require(
			_liquidateMXPFeeRate <= maxLiquidateMXPFeeRate,
			"redeem MXP fee rate should be less than 1%."
		);
		liquidateMXPFeeRate = _liquidateMXPFeeRate;
		emit RedeemMXPFeeRateChanged(liquidateMXPFeeRate);
	}

	/**
	 * @dev to set the redeem pool
	 * @param _redeemPool the address of redeem pool
	 */
	function setRedeemPool(address _redeemPool) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_redeemPool != address(0), "!_redeemPool");
		mxpRedeemPool = _redeemPool;
		emit RedeemPoolChanged(mxpRedeemPool);
	}

	/**
	 * @dev to set the stbt minter
	 * @param _stbtMinter the address of minter
	 */
	function setSTBTMinter(address _stbtMinter) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_stbtMinter != address(0), "!_stbtMinter");
		stbtMinter = _stbtMinter;
		emit RedeemMinterChanged(stbtMinter);
	}

	/**
	 * @dev to set the stbt curve pool
	 * @param _curvePool the address of curve pool
	 */
	function setCurvePool(address _curvePool) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_curvePool != address(0), "!_curvePool");
		curvePool = ICurve(_curvePool);
		emit CurvePoolChanged(_curvePool);
	}

	/**
	 * @dev to set the redeem threshold
	 * @param amount the amount of redeem threshold
	 */
	function setRedeemThreshold(uint256 amount) external onlyRole(POOL_MANAGER_ROLE) {
		redeemThreshold = amount;
		emit RedeemThresholdChanged(redeemThreshold);
	}

	/**
	 * @dev to set the price
	 * @param _lowerPrice the lower price of usdc
	 * @param _upperPrice the upper price of usdc
	 */
	function setPegPrice(
		int256 _lowerPrice,
		int256 _upperPrice
	) external onlyRole(POOL_MANAGER_ROLE) {
		lowerPrice = _lowerPrice;
		upperPrice = _upperPrice;
		emit PegPriceChanged(lowerPrice, upperPrice);
	}

	/**
	 * @dev get the exchange amount out from curve
	 * @param stbtAmount amount of stbt
	 * @param j token of index for curve pool
	 */
	function getFlashLiquidateAmountOutFromCurve(
		uint256 stbtAmount,
		int128 j
	) public view returns (uint256) {
		// From stbt to others
		return curvePool.get_dy_underlying(0, j, stbtAmount);
	}

	/// @notice get price feed answer
	function latestRoundData()
		public
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		)
	{
		return priceFeed.latestRoundData();
	}

	function _checkChainlinkResponse() internal view returns (bool) {
		(uint80 roundId, int256 answer, , uint256 updatedAt, ) = priceFeed.latestRoundData();
		// Check for an invalid roundId that is 0
		if (roundId == 0) {
			return false;
		}
		// Check for an invalid timeStamp that is 0, or in the future
		if (updatedAt == 0 || updatedAt > block.timestamp) {
			return false;
		}
		// depeg
		if (answer < lowerPrice || answer > upperPrice) {
			return false;
		}

		return true;
	}

	/**
	 * @dev Transfer a give amout of stbt to matrixport's mint pool
	 * @param caller the address of liquidator
	 * @param stbtAmount the amout of stbt
	 */
	function liquidateSTBT(address caller, uint256 stbtAmount) external {
		require(msg.sender == ustpool, "unauthorized");
		require(_checkChainlinkResponse(), "depeg");
		require(stbtAmount >= redeemThreshold, "less than redeemThreshold.");
		if (isOTC) {
			stbt.safeTransfer(mxpRedeemPool, stbtAmount);
		} else {
			stbt.approve(stbtMinter, stbtAmount);
			bytes32 salt = keccak256(abi.encodePacked(caller, stbtAmount, block.timestamp));
			IMinter(stbtMinter).redeem(stbtAmount, address(usdc), salt, bytes("redeem rustp"));
		}

		// convert to USDC amount.
		uint256 underlyingAmount = stbtAmount.div(1e12);

		uint256 liquidateFeeAmount = underlyingAmount.mul(liquidateFeeRate).div(FEE_COEFFICIENT);
		uint256 liquidateMXPFeeAmount = underlyingAmount.mul(liquidateMXPFeeRate).div(
			FEE_COEFFICIENT
		);
		uint256 amountAfterFee = underlyingAmount.sub(liquidateFeeAmount).sub(
			liquidateMXPFeeAmount
		);

		liquidationIndex++;
		liquidationDetails[liquidationIndex] = LiquidationDetail({
			id: liquidationIndex,
			timestamp: block.timestamp,
			user: caller,
			repayAmount: stbtAmount,
			receiveAmountAfterFee: amountAfterFee,
			MXPFee: liquidateMXPFeeAmount,
			protocolFee: liquidateFeeAmount,
			isDone: false
		});

		emit liquidateRequested(
			liquidationIndex,
			block.timestamp,
			caller,
			stbtAmount,
			underlyingAmount,
			amountAfterFee,
			liquidateMXPFeeAmount,
			liquidateFeeAmount
		);
	}

	/**
	 * @dev Transfer a give amout of stbt to matrixport's mint pool
	 * @param stbtAmount the amout of stbt
	 * @param j token of index for curve pool
	 * @param minReturn the minimum amount of return
	 * @param receiver used to receive token
	 */
	function flashLiquidateSTBTByCurve(
		uint256 stbtAmount,
		int128 j,
		uint256 minReturn,
		address receiver
	) external {
		require(msg.sender == ustpool, "unauthorized");
		require(j > 0, "out of range");
		require(j < 4, "out of range");

		// From stbt to others
		uint256 dy = curvePool.get_dy_underlying(0, j, stbtAmount);
		require(dy >= minReturn, "!minReturn");
		stbt.approve(address(curvePool), stbtAmount);
		curvePool.exchange_underlying(0, j, stbtAmount, dy);

		// choose from coin list.
		// Ensure that the transaction cannot succeed when the curve pool is maliciously replaced.
		IERC20 targetToken = IERC20(coins[uint256(int256(j - 1))]);

		uint256 feeAmount = dy.mul(liquidateFeeRate).div(FEE_COEFFICIENT);
		uint256 amountAfterFee = dy.sub(feeAmount);
		targetToken.safeTransfer(receiver, amountAfterFee);
		targetToken.safeTransfer(feeCollector, feeAmount);
	}

	/**
	 * @dev finalize liquidation
	 * @param _id the id of liquidation details
	 */
	function finalizeLiquidationById(uint256 _id) external {
		require(liquidationDetails[_id].user == msg.sender, "Not yours.");
		require(liquidationDetails[_id].isDone == false, "Withdrawn");
		require(
			liquidationDetails[_id].timestamp + processPeriod <= block.timestamp,
			"Not done yet."
		);

		uint256 receiveAmountAfterFee = liquidationDetails[_id].receiveAmountAfterFee;
		uint256 protocolFee = liquidationDetails[_id].protocolFee;

		liquidationDetails[_id].isDone = true;

		// the MXP fee had been charge.
		usdc.safeTransfer(msg.sender, receiveAmountAfterFee);
		usdc.safeTransfer(feeCollector, protocolFee);

		emit FinalizeLiquidation(msg.sender, receiveAmountAfterFee, protocolFee, _id);
	}
}
