// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./AccessControl.sol";

import "./IrUSTPool.sol";
import "./IiUSTP.sol";
import "./IUSTP.sol";
import "./IUniswapV3Pool.sol";

contract USTPHelper is AccessControl {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

	address public rustp;
	address public iustp;
	address public ustp;
	IERC20 public underlyingToken;
	// recovery fund wallet
	address public recovery;

	constructor(
		address _rustp,
		address _iustp,
		address _ustp,
		address _underlyingToken,
		address _recovery
	) {
		_setupRole(ADMIN_ROLE, msg.sender);
		rustp = _rustp;
		iustp = _iustp;
		ustp = _ustp;
		underlyingToken = IERC20(_underlyingToken);
		require(_recovery != address(0), "!_recovery");
		recovery = _recovery;
	}

	/**
	 * @dev Mint rUSTP
	 * @param amount the amout of underlying
	 */
	function mintrUSTP(uint256 amount) external returns (uint256) {
		address user = msg.sender;
		underlyingToken.safeTransferFrom(user, address(this), amount);
		underlyingToken.approve(rustp, amount);
		uint256 beforeAmount = IERC20(rustp).balanceOf(address(this));
		IrUSTPool(rustp).supplyUSDC(amount);
		uint256 afterAmount = IERC20(rustp).balanceOf(address(this));
		uint256 mintAmount = afterAmount.sub(beforeAmount);
		IERC20(rustp).safeTransfer(msg.sender, mintAmount);
		return mintAmount;
	}

	/**
	 * @dev Mint iUSTP
	 * @param amount the amout of underlying
	 */
	function mintiUSTP(uint256 amount) external returns (uint256) {
		address user = msg.sender;
		underlyingToken.safeTransferFrom(user, address(this), amount);
		underlyingToken.approve(rustp, amount);
		uint256 beforeAmount = IERC20(rustp).balanceOf(address(this));
		IrUSTPool(rustp).supplyUSDC(amount);
		uint256 afterAmount = IERC20(rustp).balanceOf(address(this));
		uint256 userAmount = afterAmount.sub(beforeAmount);

		IERC20(rustp).approve(iustp, userAmount);
		uint256 beforeIUSTP = IERC20(iustp).balanceOf(address(this));
		IiUSTP(iustp).wrap(userAmount);
		uint256 afterIUSTP = IERC20(iustp).balanceOf(address(this));

		uint256 mintAmount = afterIUSTP.sub(beforeIUSTP);
		IERC20(iustp).safeTransfer(msg.sender, afterIUSTP.sub(beforeIUSTP));

		return mintAmount;
	}

	/**
	 * @dev Mint USTP
	 * @param amount the amout of underlying
	 */
	function mintUSTP(uint256 amount) external returns (uint256) {
		address user = msg.sender;
		underlyingToken.safeTransferFrom(user, address(this), amount);
		underlyingToken.approve(rustp, amount);
		uint256 beforeAmount = IERC20(rustp).balanceOf(address(this));
		IrUSTPool(rustp).supplyUSDC(amount);
		uint256 afterAmount = IERC20(rustp).balanceOf(address(this));
		uint256 userAmount = afterAmount.sub(beforeAmount);

		IERC20(rustp).approve(ustp, userAmount);
		uint256 beforeUSTP = IERC20(ustp).balanceOf(address(this));
		IUSTP(ustp).deposit(userAmount);
		uint256 afterUSTP = IERC20(ustp).balanceOf(address(this));

		uint256 mintAmount = afterUSTP.sub(beforeUSTP);
		IERC20(ustp).safeTransfer(msg.sender, mintAmount);

		return mintAmount;
	}

	/**
	 * @dev Wrap iUSTP to USTP
	 * @param amount the amout of iUSTP
	 */
	function wrapiUSTPToUSTP(uint256 amount) external returns (uint256) {
		uint256 mintAmount = _wrapiUSTPToUSTP(amount);
		IERC20(ustp).safeTransfer(msg.sender, mintAmount);

		return mintAmount;
	}

	function _wrapiUSTPToUSTP(uint256 amount) internal returns (uint256) {
		address user = msg.sender;
		uint256 beforerUSTP = IERC20(rustp).balanceOf(address(this));
		IERC20(iustp).safeTransferFrom(user, address(this), amount);
		IiUSTP(iustp).unwrap(amount);
		uint256 afterrUSTP = IERC20(rustp).balanceOf(address(this));

		uint256 userrUSTPAmount = afterrUSTP.sub(beforerUSTP);

		IERC20(rustp).approve(ustp, userrUSTPAmount);
		uint256 beforeUSTP = IERC20(ustp).balanceOf(address(this));
		IUSTP(ustp).deposit(userrUSTPAmount);

		uint256 afterUSTP = IERC20(ustp).balanceOf(address(this));

		uint256 mintAmount = afterUSTP.sub(beforeUSTP);

		return mintAmount;
	}

	/**
	 * @dev Wrap rUSTP to USTP
	 * @param amount the amout of rUSTP
	 */
	function wraprUSTPToUSTP(uint256 amount) external returns (uint256) {
		uint256 mintAmount = _wraprUSTPToUSTP(amount);
		IERC20(ustp).safeTransfer(msg.sender, mintAmount);
		return mintAmount;
	}

	function _wraprUSTPToUSTP(uint256 amount) internal returns (uint256) {
		address user = msg.sender;
		IERC20(rustp).safeTransferFrom(user, address(this), amount);

		IERC20(rustp).approve(ustp, amount);
		uint256 beforeUSTP = IERC20(ustp).balanceOf(address(this));
		IUSTP(ustp).deposit(amount);

		uint256 afterUSTP = IERC20(ustp).balanceOf(address(this));

		uint256 mintAmount = afterUSTP.sub(beforeUSTP);
		return mintAmount;
	}

	/**
	 * @dev Wrap USTP to iUSTP
	 * @param amount the amout of USTP
	 */
	function wrapUSTPToiUSTP(uint256 amount) external returns (uint256) {
		uint256 mintAmount = _wrapUSTPToiUSTP(amount);
		IERC20(iustp).safeTransfer(msg.sender, mintAmount);
		return mintAmount;
	}

	function _wrapUSTPToiUSTP(uint256 amount) internal returns (uint256) {
		address user = msg.sender;
		uint256 beforerUSTP = IERC20(rustp).balanceOf(address(this));
		IERC20(ustp).safeTransferFrom(user, address(this), amount);
		IUSTP(ustp).withdraw(amount);
		uint256 afterrUSTP = IERC20(rustp).balanceOf(address(this));
		uint256 userrUSTPAmount = afterrUSTP.sub(beforerUSTP);

		IERC20(rustp).approve(iustp, userrUSTPAmount);

		uint256 beforeIUSTP = IERC20(iustp).balanceOf(address(this));
		IiUSTP(iustp).wrap(userrUSTPAmount);
		uint256 afterIUSTP = IERC20(iustp).balanceOf(address(this));

		uint256 mintAmount = afterIUSTP.sub(beforeIUSTP);

		return mintAmount;
	}

	// swap
	uint160 internal constant MIN_SQRT_RATIO = 4295128739;
	uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
	bytes32 internal constant POOL_INIT_CODE_HASH =
		0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

	address public factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

	function swapToTokens(
		address tokenIn,
		address tokenOut,
		uint256 amountIn,
		uint256 minAmount,
		uint160 sqrtPriceLimitX96,
		uint24 fee
	) public returns (uint256 amountOut) {
		require(tokenIn == rustp || tokenIn == iustp || tokenIn == ustp, "f");
		uint256 realAmountIn = amountIn;
		if (tokenIn == rustp) {
			realAmountIn = _wraprUSTPToUSTP(amountIn);
		} else if (tokenIn == iustp) {
			realAmountIn = _wrapiUSTPToUSTP(amountIn);
		} else {
			IERC20(ustp).safeTransferFrom(msg.sender, address(this), realAmountIn);
		}

		amountOut = exactInputInternal(
			realAmountIn,
			msg.sender,
			sqrtPriceLimitX96,
			abi.encode(ustp, tokenOut, fee)
		);
		require(amountOut >= minAmount, "lower than minAmount");
	}

	/// @dev Performs a single exact input swap
	function exactInputInternal(
		uint256 amountIn,
		address recipient,
		uint160 sqrtPriceLimitX96,
		bytes memory data
	) internal returns (uint256 amountOut) {
		(address tokenIn, address tokenOut, uint24 fee) = abi.decode(
			data,
			(address, address, uint24)
		);

		bool zeroForOne = tokenIn < tokenOut;

		(int256 amount0, int256 amount1) = getPool(tokenIn, tokenOut, fee).swap(
			recipient,
			zeroForOne,
			toInt256(amountIn),
			sqrtPriceLimitX96 == 0
				? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
				: sqrtPriceLimitX96,
			data
		);

		return uint256(-(zeroForOne ? amount1 : amount0));
	}

	/// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
	function getPool(
		address tokenA,
		address tokenB,
		uint24 fee
	) internal view returns (IUniswapV3Pool) {
		if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
		return IUniswapV3Pool(computeAddress(tokenA, tokenB, fee));
	}

	function computeAddress(
		address token0,
		address token1,
		uint24 fee
	) internal view returns (address pool) {
		require(token0 < token1);
		pool = address(
			uint160(
				uint256(
					keccak256(
						abi.encodePacked(
							hex"ff",
							factory,
							keccak256(abi.encode(token0, token1, fee)),
							POOL_INIT_CODE_HASH
						)
					)
				)
			)
		);
	}

	function uniswapV3SwapCallback(
		int256 amount0Delta,
		int256 amount1Delta,
		bytes calldata _data
	) external {
		require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
		(address tokenIn, address tokenOut, uint24 fee) = abi.decode(
			_data,
			(address, address, uint24)
		);
		require(msg.sender == address(getPool(tokenIn, tokenOut, fee)));

		(bool isExactInput, uint256 amountToPay) = amount0Delta > 0
			? (tokenIn < tokenOut, uint256(amount0Delta))
			: (tokenOut < tokenIn, uint256(amount1Delta));

		if (isExactInput) {
			IERC20(tokenIn).safeTransfer(msg.sender, amountToPay);
		} else {
			IERC20(tokenOut).safeTransfer(msg.sender, amountToPay);
		}
	}

	function toInt256(uint256 y) internal pure returns (int256 z) {
		require(y < 2 ** 255);
		z = int256(y);
	}

	/**
	 * @dev Allows to recover any ERC20 token
	 * @param recover Using to receive recovery of fund
	 * @param tokenAddress Address of the token to recover
	 * @param amountToRecover Amount of collateral to transfer
	 */
	function recoverERC20(
		address recover,
		address tokenAddress,
		uint256 amountToRecover
	) external onlyRole(ADMIN_ROLE) {
		IERC20(tokenAddress).safeTransfer(recover, amountToRecover);
	}
}
