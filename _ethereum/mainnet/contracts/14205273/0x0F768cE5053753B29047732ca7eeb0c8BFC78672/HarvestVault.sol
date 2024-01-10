//SPDX-License-Identifier: MIT
pragma solidity >=0.6.5 <0.8.0;

// import "./console.sol";

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IHarvestVaultAdapter.sol";
import "./IVaultAdapter.sol";
import "./TransferHelper.sol";

/// @title Pool
///
/// @dev A library which provides the Vault data struct and associated functions.
library HarvestVault {
	using HarvestVault for Data;
	using HarvestVault for List;
	using TransferHelper for address;
	using SafeMath for uint256;

	struct Data {
		IHarvestVaultAdapter adapter;
		uint256 totalDeposited;
	}

	struct List {
		Data[] elements;
	}

	/// @dev Gets the total amount of assets deposited in the vault.
	///
	/// @return the total assets.
	function totalValue(Data storage _self) internal view returns (uint256) {
		return _self.adapter.totalValue();
	}

	/// @dev Gets the token that the vault accepts.
	///
	/// @return the accepted token.
	function token(Data storage _self) internal view returns (address) {
		return _self.adapter.token();
	}

	/// @dev Deposits funds from the caller into the vault.
	///
	/// @param _amount the amount of funds to deposit.
	function deposit(Data storage _self, uint256 _amount) internal returns (uint256) {
		// Push the token that the vault accepts onto the stack to save gas.
		address _token = _self.token();
		_token.safeTransfer(address(_self.adapter), _amount);
		_self.adapter.deposit(_amount);
		_self.totalDeposited = _self.totalDeposited.add(_amount);

		// Stake all lp to farm.
		IERC20 _lpToken = IERC20(_self.adapter.lpToken());
		uint256 _lpTokenAmount = _lpToken.balanceOf(address(_self.adapter));
		_self.adapter.stake(_lpTokenAmount);

		return _amount;
	}

	/// @dev Withdraw deposited funds from the vault.
	///
	/// @param _recipient the account to withdraw the tokens to.
	/// @param _amount    the amount of tokens to withdraw.
	function withdraw(
		Data storage _self,
		address _recipient,
		uint256 _amount
	) internal returns (uint256, uint256) {
		(uint256 _withdrawnAmount, uint256 _decreasedValue) = _self.directWithdraw(_recipient, _amount);
		_self.totalDeposited = _self.totalDeposited.sub(_decreasedValue);
		return (_withdrawnAmount, _decreasedValue);
	}

	/// @dev Directly withdraw deposited funds from the vault.
	///
	/// @param _recipient the account to withdraw the tokens to.
	/// @param _amount    the amount of tokens to withdraw.
	function directWithdraw(
		Data storage _self,
		address _recipient,
		uint256 _amount
	) internal returns (uint256, uint256) {
		address _token = _self.token();

		uint256 _startingBalance = IERC20(_token).balanceOf(_recipient);
		uint256 _startingTotalValue = _self.totalValue();

		_self.adapter.unstake(_amount);
		_self.adapter.withdraw(_recipient, _amount);

		uint256 _endingBalance = IERC20(_token).balanceOf(_recipient);

		uint256 _withdrawnAmount = _endingBalance.sub(_startingBalance);

		uint256 _endingTotalValue = _self.totalValue();
		uint256 _decreasedValue = _startingTotalValue.sub(_endingTotalValue);

		return (_withdrawnAmount, _decreasedValue);
	}

	/// @dev Withdraw all the deposited funds from the vault.
	///
	/// @param _recipient the account to withdraw the tokens to.
	function withdrawAll(Data storage _self, address _recipient) internal returns (uint256, uint256) {
		uint256 _withdrawAmount = _self.totalDeposited;
		if (_withdrawAmount > _self.totalValue()) {
			_withdrawAmount = _self.totalValue(); // This fix with rounding problem.
		}
		return _self.withdraw(_recipient, _withdrawAmount);
	}

	/// @dev Harvests yield from the vault.
	///
	/// @param _recipient the account to withdraw the harvested yield to.
	function harvest(Data storage _self, address _recipient) internal returns (uint256, uint256) {
		_self.adapter.claim();
		if (_self.totalValue() <= _self.totalDeposited) {
			return (0, 0);
		}
		uint256 _withdrawAmount = _self.totalValue().sub(_self.totalDeposited);

		(uint256 _withdrawnAmount, uint256 _decreasedValue) = _self.directWithdraw(_recipient, _withdrawAmount);
		IVaultAdapter(_recipient).deposit(_withdrawnAmount);
		return (_withdrawnAmount, _decreasedValue);
	}

	/// @dev Adds a element to the list.
	///
	/// @param _element the element to add.
	function push(List storage _self, Data memory _element) internal {
		for (uint256 i = 0; i < _self.elements.length; i++) {
			// Avoid duplicated adapter
			require(address(_element.adapter) != address(_self.elements[i].adapter), '!Repeat adapter');
		}
		_self.elements.push(_element);
	}

	/// @dev Gets a element from the list.
	///
	/// @param _index the index in the list.
	///
	/// @return the element at the specified index.
	function get(List storage _self, uint256 _index) internal view returns (Data storage) {
		return _self.elements[_index];
	}

	/// @dev Gets the last element in the list.
	///
	/// This function will revert if there are no elements in the list.
	///
	/// @return the last element in the list.
	function last(List storage _self) internal view returns (Data storage) {
		return _self.elements[_self.lastIndex()];
	}

	/// @dev Gets the index of the last element in the list.
	///
	/// This function will revert if there are no elements in the list.
	///
	/// @return the index of the last element.
	function lastIndex(List storage _self) internal view returns (uint256) {
		uint256 _length = _self.length();
		return _length.sub(1, 'Vault.List: empty');
	}

	/// @dev Gets the number of elements in the list.
	///
	/// @return the number of elements.
	function length(List storage _self) internal view returns (uint256) {
		return _self.elements.length;
	}
}
