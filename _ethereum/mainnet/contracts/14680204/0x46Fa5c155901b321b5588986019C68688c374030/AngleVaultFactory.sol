// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ClonesUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./AngleVault.sol";
import "./GaugeMultiRewards.sol";

/**
 * @title Factory contract usefull for creating new angle vaults that supports LP related
 * to the angle platform, and the gauge multi rewards attached to it.
 */
contract AngleVaultFactory {
	using ClonesUpgradeable for address;

	address public vaultImpl = address(new AngleVault());
	address public gaugeImpl = address(new GaugeMultiRewards());

	event VaultDeployed(address proxy, address lpToken, address impl);
	event GaugeDeployed(address proxy, address stakeToken, address impl);

	/**
	@dev Function to clone Angle Vault and its gauge contracts 
	@param _vaultLPToken Angle LP token related to the vault 
	@param _vaultGovernance vault governance address
	@param _vaultName vault name
	@param _vaultSymbol vault symbol
	@param _vaultAngleStrategy angle strategy proxy
	@param _gaugeGovernance gauge governance address
	@param _gaugeName gauge name
	@param _gaugeSymbol gauge symbol 
	 */
	function cloneAndInit(
		ERC20Upgradeable _vaultLPToken,
		address _vaultGovernance,
		string memory _vaultName,
		string memory _vaultSymbol,
		AngleStrategy _vaultAngleStrategy,
		address _gaugeGovernance,
		string memory _gaugeName,
		string memory _gaugeSymbol
	) public {
		address vaultImplAddress = _cloneAndInitVault(
			vaultImpl,
			_vaultLPToken,
			_vaultGovernance,
			_vaultName,
			_vaultSymbol,
			_vaultAngleStrategy
		);
		address gaugeImplAddress = _cloneAndInitGauge(
			gaugeImpl,
			vaultImplAddress,
			_gaugeGovernance,
			_gaugeName,
			_gaugeSymbol
		);
		AngleVault(vaultImplAddress).setGaugeMultiRewards(gaugeImplAddress);
		AngleVault(vaultImplAddress).setGovernance(_vaultGovernance);
	}

	/**
	@dev Internal function to clone the vault 
	@param _impl address of contract to clone
	@param _lpToken angle LP token address 
	@param _governance governance address 
	@param _name vault name
	@param _symbol vault symbol
	@param _angleStrategy angle strategy proxy
	 */
	function _cloneAndInitVault(
		address _impl,
		ERC20Upgradeable _lpToken,
		address _governance,
		string memory _name,
		string memory _symbol,
		AngleStrategy _angleStrategy
	) internal returns (address) {
		AngleVault deployed = cloneVault(
			_impl,
			_lpToken,
			keccak256(abi.encodePacked(_governance, _name, _symbol, _angleStrategy))
		);
		deployed.init(_lpToken, address(this), _name, _symbol, _angleStrategy);
		return address(deployed);
	}

	/**
	@dev Internal function to clone the gauge multi rewards
	@param _impl address of contract to clone
	@param _stakingToken sd LP token address 
	@param _governance governance address 
	@param _name gauge name
	@param _symbol gauge symbol
	 */
	function _cloneAndInitGauge(
		address _impl,
		address _stakingToken,
		address _governance,
		string memory _name,
		string memory _symbol
	) internal returns (address) {
		GaugeMultiRewards deployed = cloneGauge(
			_impl,
			_stakingToken,
			keccak256(abi.encodePacked(_governance, _name, _symbol))
		);
		deployed.init(_stakingToken, _stakingToken, _governance, _name, _symbol);
		return address(deployed);
	}

	/**
	@dev Internal function that deploy and returns a clone of vault impl
	@param _impl address of contract to clone
	@param _lpToken angle LP token address
	@param _paramsHash governance+name+symbol+strategy parameters hash
	 */
	function cloneVault(
		address _impl,
		ERC20Upgradeable _lpToken,
		bytes32 _paramsHash
	) internal returns (AngleVault) {
		address deployed = address(_impl).cloneDeterministic(keccak256(abi.encodePacked(address(_lpToken), _paramsHash)));
		emit VaultDeployed(deployed, address(_lpToken), _impl);
		return AngleVault(deployed);
	}

	/**
	@dev Internal function that deploy and returns a clone of gauge impl
	@param _impl address of contract to clone
	@param _stakingToken sd LP token address
	@param _paramsHash governance+name+symbol parameters hash
	 */
	function cloneGauge(
		address _impl,
		address _stakingToken,
		bytes32 _paramsHash
	) internal returns (GaugeMultiRewards) {
		address deployed = address(_impl).cloneDeterministic(
			keccak256(abi.encodePacked(address(_stakingToken), _paramsHash))
		);
		emit GaugeDeployed(deployed, _stakingToken, _impl);
		return GaugeMultiRewards(deployed);
	}

	/**
	@dev Function that predicts the future address passing the parameters
	@param _impl address of contract to clone
	@param _token token (LP or sdLP)
	@param _paramsHash parameters hash
	 */
	function predictAddress(
		address _impl,
		IERC20 _token,
		bytes32 _paramsHash
	) public view returns (address) {
		return address(_impl).predictDeterministicAddress(keccak256(abi.encodePacked(address(_token), _paramsHash)));
	}
}
