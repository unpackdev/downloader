// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./TimelockControllerUpgradeable.sol";
// import "./GovernorTimelockControlUpgradeable.sol";
import "./IPolemarch.sol";
import "./Types.sol";
import "./ConfigurationService.sol";
import "./ExchequerService.sol";
import "./SupplyService.sol";
import "./DebtService.sol";
import "./PolemarchStorage.sol";


contract Polemarch is Initializable, OwnableUpgradeable, PolemarchStorage, IPolemarch {
	using ExchequerService for Types.Exchequer;

	modifier onlyGovernance {
		require(msg.sender == address(_timelock), "Not timelock");
		_;
	}

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
	    _disableInitializers();
	}

	function initialize() external virtual initializer {
		__Ownable_init();
		_maxExchequersCount = 10;
	}

	function addExchequer(
		address underlyingAsset,
		address sTokenAddress,
		address dTokenAddress,
		address gTokenAddress,
		uint8 decimals,
		uint256 protocolBorrowFee
	) external onlyOwner {
		if (ExchequerService.addExchequer(
			_exchequers,
			_exchequersList,
			underlyingAsset,
			sTokenAddress,
			dTokenAddress,
			gTokenAddress,
			decimals,
			protocolBorrowFee,
			_exchequersCount,
			_maxExchequersCount
		)) {
			_exchequersCount++;
		}
	}

	function supply(
		address underlyingAsset,
		uint256 amount
	) public virtual override {
		SupplyService.addSupply(_exchequers, underlyingAsset, _THURMAN, amount);
	}

	function grantSupply(
		address underlyingAsset,
		uint256 amount
	) public virtual override {
		SupplyService.addGrantSupply(_exchequers, underlyingAsset, _THURMAN, amount);
	}

	function withdraw(
		address underlyingAsset,
		uint256 amount
	) public virtual override {
		SupplyService.withdraw(_exchequers, underlyingAsset, _THURMAN, amount);
	}

	function grantWithdraw(
		address underlyingAsset,
		uint256 amount
	) public virtual override {
		SupplyService.grantWithdraw(_exchequers, underlyingAsset, _THURMAN, amount);
	}

	function deleteExchequer(address underlyingAsset) external onlyOwner {
		ExchequerService.deleteExchequer(_exchequers, _exchequersList, underlyingAsset);
	}

	function getExchequer(address underlyingAsset) external view returns (Types.Exchequer memory) {
		return _exchequers[underlyingAsset];
	}

	function createLineOfCredit(
		address borrower,
		address underlyingAsset,
		uint256 borrowMax,
		uint128 rate,
		uint40 termDays
	) external onlyGovernance {
		DebtService.createLineOfCredit(
			_exchequers,
			_linesOfCredit,
			_linesOfCreditCount,
			borrower,
			underlyingAsset,
			borrowMax,
			rate,
			termDays
		);
		_linesOfCreditCount++;
	}

	function borrow(
		address underlyingAsset,
		uint256 amount
	) public virtual override {
		DebtService.borrow(
			_exchequers, 
			_linesOfCredit,
			underlyingAsset,
			amount
		);
	}

	function repay(
		address underlyingAsset,
		uint256 amount
	) public virtual override {
		DebtService.repay(
			_exchequers,
			_linesOfCredit,
			underlyingAsset,
			amount
		);
	}

	function markDelinquent(address underlyingAsset, address borrower) external onlyOwner {
		DebtService.markDelinquent(
			_exchequers, 
			_linesOfCredit, 
			borrower, 
			underlyingAsset
		);
	}

	function closeLineOfCredit(address underlyingAsset, address borrower) external onlyOwner {
		DebtService.closeLineOfCredit(
			_exchequers,
			_linesOfCredit,
			borrower,
			underlyingAsset
		);
	}

	function getLineOfCredit(address borrower) external view returns (Types.LineOfCredit memory) {
		return _linesOfCredit[borrower];
	}

	function getNormalizedReturn(address underlyingAsset)
		external 
		view 
		virtual 
		override 
		returns (uint256)
	{
		return _exchequers[underlyingAsset].getNormalizedReturn();
	}

	function setThurmanToken(address governanceToken) external onlyOwner {
		_THURMAN = governanceToken;
	}

	function setTimelock(TimelockControllerUpgradeable timelock) external onlyOwner {
		_timelock = timelock;
	}

	function setExchequerBorrowing(address underlyingAsset, bool enabled) external onlyOwner {
		ConfigurationService.setExchequerBorrowing(_exchequers, underlyingAsset, enabled);
	}

	function setExchequerActive(address underlyingAsset, bool active) external onlyOwner {
		ConfigurationService.setExchequerActive(_exchequers, underlyingAsset, active);
	}

	function setSupplyCap(address underlyingAsset, uint256 supplyCap) external onlyOwner {
		ConfigurationService.setSupplyCap(_exchequers, underlyingAsset, supplyCap);
	}

	function setBorrowCap(address underlyingAsset, uint256 borrowCap) external onlyOwner {
		ConfigurationService.setBorrowCap(_exchequers, underlyingAsset, borrowCap);
	}
	// function closeLineOfCredit(){}
}