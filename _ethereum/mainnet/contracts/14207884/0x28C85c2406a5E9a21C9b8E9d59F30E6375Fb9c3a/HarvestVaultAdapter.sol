// SPDX-License-Identifier: MIT
pragma solidity >=0.6.5 <0.8.0;

pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./FixedPointMath.sol";
import "./TransferHelper.sol";
import "./IDetailedERC20.sol";
import "./IHarvestVaultAdapter.sol";
import "./IHarvestVault.sol";
import "./IHarvestFarm.sol";

/// @title YearnVaultAdapter
///
/// @dev A vault adapter implementation which wraps a yEarn vault.
contract HarvestVaultAdapter is IHarvestVaultAdapter {
	using FixedPointMath for FixedPointMath.uq192x64;
	using TransferHelper for address;
	using SafeMath for uint256;

	/// @dev The vault that the adapter is wrapping.
	IHarvestVault public vault;

	IHarvestFarm public farm;

	/// @dev The address which has admin control over this contract.
	address public admin;

	/// @dev The decimals of the token.
	uint256 public decimals;

	address public treasury;

	constructor(
		IHarvestVault _vault,
		IHarvestFarm _farm,
		address _admin,
		address _treasury
	) public {
		vault = _vault;
		farm = _farm;
		admin = _admin;
		treasury = _treasury;
		updateVaultApproval();
		updateFarmApproval();
		decimals = _vault.decimals();
	}

	/// @dev A modifier which reverts if the caller is not the admin.
	modifier onlyAdmin() {
		require(admin == msg.sender, 'HarvestVaultAdapter: only admin');
		_;
	}

	/// @dev Gets the token that the vault accepts.
	///
	/// @return the accepted token.
	function token() external view override returns (address) {
		return vault.underlying();
	}

	function lpToken() external view override returns (address) {
		return address(vault);
	}

	function lpTokenInFarm() public view override returns (uint256) {
		return farm.balanceOf(address(this));
	}

	/// @dev Gets the total value of the assets that the adapter holds in the vault.
	///
	/// @return the total assets.
	function totalValue() external view override returns (uint256) {
		return _sharesToTokens(lpTokenInFarm());
	}

	/// @dev Deposits tokens into the vault.
	///
	/// @param _amount the amount of tokens to deposit into the vault.
	function deposit(uint256 _amount) external override {
		vault.deposit(_amount);
	}

	/// @dev Withdraws tokens from the vault to the recipient.
	///
	/// This function reverts if the caller is not the admin.
	///
	/// @param _recipient the account to withdraw the tokes to.
	/// @param _amount    the amount of tokens to withdraw.
	function withdraw(address _recipient, uint256 _amount) external override onlyAdmin {
		vault.withdraw(_tokensToShares(_amount));
		address _token = vault.underlying();
		uint256 _balance = IERC20(_token).balanceOf(address(this));
		_token.safeTransfer(_recipient, _balance);
	}

	/// @dev stake into farming pool.
	function stake(uint256 _amount) external override {
		farm.stake(_amount);
	}

	/// @dev unstake from farming pool.
	function unstake(uint256 _amount) external override onlyAdmin {
		farm.withdraw(_tokensToShares(_amount));
	}

	function claim() external override {
		farm.getReward();
		address _rewardToken = farm.rewardToken();
		uint256 _balance = IERC20(_rewardToken).balanceOf(address(this));
		if (_balance > 0) {
			_rewardToken.safeTransfer(treasury, _balance);
		}
	}

	/// @dev Updates the vaults approval of the token to be the maximum value.
	function updateVaultApproval() public {
		address _token = vault.underlying();
		_token.safeApprove(address(vault), uint256(-1));
	}

	/// @dev Update the farm approval.
	function updateFarmApproval() public {
		address(vault).safeApprove(address(farm), uint256(-1));
	}

	/// @dev Computes the number of tokens an amount of shares is worth.
	///
	/// @param _sharesAmount the amount of shares.
	///
	/// @return the number of tokens the shares are worth.

	function _sharesToTokens(uint256 _sharesAmount) internal view returns (uint256) {
		return _sharesAmount.mul(vault.getPricePerFullShare()).div(10**decimals);
	}

	/// @dev Computes the number of shares an amount of tokens is worth.
	///
	/// @param _tokensAmount the amount of shares.
	///
	/// @return the number of shares the tokens are worth.
	function _tokensToShares(uint256 _tokensAmount) internal view returns (uint256) {
		return _tokensAmount.mul(10**decimals).div(vault.getPricePerFullShare());
	}
}
