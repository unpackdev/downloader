// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseAccumulator.sol";
import "./IStableMaster.sol";

/// @title A contract that can claim sanUSDC_EUR rewards, burn them for USDC and mint agEUR to send to LGV4
/// @author StakeDAO
contract AngleAccumulatorV2 is BaseAccumulator {
	address public constant STABLE_MASTER = 0x5adDc89785D75C86aB939E9e15bfBBb7Fc086A87;
	address public constant POOL_MANAGER = 0xe9f183FC656656f1F17af1F2b0dF79b8fF9ad8eD;
	address public constant SAN_USDC_EUR = 0x9C215206Da4bf108aE5aEEf9dA7caD3352A36Dad;
	address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

	/* ========== CONSTRUCTOR ========== */
	constructor(address _tokenReward) BaseAccumulator(_tokenReward) {}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Claims rewards from the locker and notify an amount to the LGV4
	/// @param _amount amount to notify after the claim
	function claimAndNotify(uint256 _amount) external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimRewards(SAN_USDC_EUR, address(this));
		_zap();
		_notifyReward(tokenReward, _amount);
	}

	/// @notice Claims rewards from the locker and notify all to the LGV4
	function claimAndNotifyAll() external {
		require(locker != address(0), "locker not set");
		ILocker(locker).claimRewards(SAN_USDC_EUR, address(this));
		_zap();
		uint256 amount = IERC20(tokenReward).balanceOf(address(this));
		_notifyReward(tokenReward, amount);
	}

	/// @notice utility function for minting agEUR from the feedistributor token reward
	function _zap() internal {
		// burn sanLP to receive USDC
		uint256 sanLpAmount = IERC20(SAN_USDC_EUR).balanceOf(address(this));
		IERC20(SAN_USDC_EUR).approve(STABLE_MASTER, sanLpAmount);
		IStableMaster(STABLE_MASTER).withdraw(sanLpAmount, address(this), address(this), POOL_MANAGER);
		// mint agEUR with USDC retrieved
		uint256 usdcAmount = IERC20(USDC).balanceOf(address(this));
		IERC20(USDC).approve(STABLE_MASTER, usdcAmount);
		IStableMaster(STABLE_MASTER).mint(usdcAmount, address(this), POOL_MANAGER, 0);
	}
}
