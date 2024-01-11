// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ClonesUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./AngleVault.sol";
import "./IGaugeController.sol";
import "./ILiquidityGaugeStrat.sol";

interface AngleLiquidityGauge {
	function staking_token() external view returns (address);
}

/**
 * @title Factory contract usefull for creating new angle vaults that supports LP related
 * to the angle platform, and the gauge multi rewards attached to it.
 */
contract AngleVaultFactory {
	using ClonesUpgradeable for address;

	address public vaultImpl = address(new AngleVault());
	address public gaugeImpl;
	address public constant governance = 0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063;
	address public constant gaugeController = 0x9aD7e7b0877582E14c17702EecF49018DD6f2367;
	address public constant ANGLE = 0x31429d1856aD1377A8A0079410B297e1a9e214c2;
	address public constant VESDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;
	address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
	address public constant VEBOOST = 0xD67bdBefF01Fc492f1864E61756E5FBB3f173506;
	address public angleStrategy;
	address public sdtDistributor;
	event VaultDeployed(address proxy, address lpToken, address impl);
	event GaugeDeployed(address proxy, address stakeToken, address impl);

	constructor(
		address _gaugeImpl,
		address _angleStrategy,
		address _sdtDistributor
	) {
		gaugeImpl = _gaugeImpl;
		angleStrategy = _angleStrategy;
		sdtDistributor = _sdtDistributor;
	}

	/**
	@dev Function to clone Angle Vault and its gauge contracts 
	@param _angleGauge Angle liquidity gauge address
	 */
	function cloneAndInit(address _angleGauge) public {
		uint256 weight = IGaugeController(gaugeController).get_gauge_weight(_angleGauge);
		require(weight > 0, "must have weight");
		address vaultLpToken = AngleLiquidityGauge(_angleGauge).staking_token();
		string memory tokenSymbol = ERC20Upgradeable(vaultLpToken).symbol();
		string memory tokenName = ERC20Upgradeable(vaultLpToken).name();
		address vaultImplAddress = _cloneAndInitVault(
			vaultImpl,
			ERC20Upgradeable(vaultLpToken),
			governance,
			string(abi.encodePacked("sd", tokenName, " Vault")),
			string(abi.encodePacked("sd", tokenSymbol, "-vault"))
		);
		address gaugeImplAddress = _cloneAndInitGauge(gaugeImpl, vaultImplAddress, governance, tokenSymbol);
		AngleVault(vaultImplAddress).setLiquidityGauge(gaugeImplAddress);
		AngleVault(vaultImplAddress).setGovernance(governance);
		AngleStrategy(angleStrategy).toggleVault(vaultImplAddress);
		AngleStrategy(angleStrategy).setGauge(vaultLpToken, _angleGauge);
		AngleStrategy(angleStrategy).setMultiGauge(_angleGauge, gaugeImplAddress);
		AngleStrategy(angleStrategy).manageFee(AngleStrategy.MANAGEFEE.PERFFEE, _angleGauge, 200); //%2 default
		AngleStrategy(angleStrategy).manageFee(AngleStrategy.MANAGEFEE.VESDTFEE, _angleGauge, 500); //%5 default
		AngleStrategy(angleStrategy).manageFee(AngleStrategy.MANAGEFEE.ACCUMULATORFEE, _angleGauge, 800); //%8 default
		AngleStrategy(angleStrategy).manageFee(AngleStrategy.MANAGEFEE.CLAIMERREWARD, _angleGauge, 50); //%0.5 default
		ILiquidityGaugeStrat(gaugeImplAddress).add_reward(ANGLE, angleStrategy);
		ILiquidityGaugeStrat(gaugeImplAddress).commit_transfer_ownership(governance);
	}

	/**
	@dev Internal function to clone the vault 
	@param _impl address of contract to clone
	@param _lpToken angle LP token address 
	@param _governance governance address 
	@param _name vault name
	@param _symbol vault symbol
	 */
	function _cloneAndInitVault(
		address _impl,
		ERC20Upgradeable _lpToken,
		address _governance,
		string memory _name,
		string memory _symbol
	) internal returns (address) {
		AngleVault deployed = cloneVault(
			_impl,
			_lpToken,
			keccak256(abi.encodePacked(_governance, _name, _symbol, angleStrategy))
		);
		deployed.init(_lpToken, address(this), _name, _symbol, AngleStrategy(angleStrategy));
		return address(deployed);
	}

	/**
	@dev Internal function to clone the gauge multi rewards
	@param _impl address of contract to clone
	@param _stakingToken sd LP token address 
	@param _governance governance address 
	@param _symbol gauge symbol
	 */
	function _cloneAndInitGauge(
		address _impl,
		address _stakingToken,
		address _governance,
		string memory _symbol
	) internal returns (address) {
		ILiquidityGaugeStrat deployed = cloneGauge(_impl, _stakingToken, keccak256(abi.encodePacked(_governance, _symbol)));
		deployed.initialize(_stakingToken, address(this), SDT, VESDT, VEBOOST, sdtDistributor, _stakingToken, _symbol);
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
	) internal returns (ILiquidityGaugeStrat) {
		address deployed = address(_impl).cloneDeterministic(
			keccak256(abi.encodePacked(address(_stakingToken), _paramsHash))
		);
		emit GaugeDeployed(deployed, _stakingToken, _impl);
		return ILiquidityGaugeStrat(deployed);
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
