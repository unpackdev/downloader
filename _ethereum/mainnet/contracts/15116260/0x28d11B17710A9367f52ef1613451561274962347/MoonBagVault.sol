// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IERC20.sol";

contract MoonBagVault is Context, Ownable, ReentrancyGuard {

	address public moonAddress;

	struct Bag {
		uint256 date; // when the bag was created
		uint256 amount; // the amount locked in the bag
	}
	mapping(address => uint256) private _balance;
	mapping(address => uint256) private _availableBalance;
	mapping(address => Bag[]) private _bags;
	mapping(address => uint256) private _bagsLastUpdated;

	uint256 private _totalLocked;

	constructor(address _moonAddress) {
		moonAddress = _moonAddress;
	}
	
	function lock(address account, uint256 amount) public nonReentrant {
		require(
			_msgSender() == account || _msgSender() == moonAddress,
			"Cannot lock on behalf of another account."
		);

		IERC20(moonAddress).transferFrom(account, address(this), amount);
		_balance[account] += amount;
		_totalLocked += amount;
		_bags[account].push(Bag(block.timestamp, amount));
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balance[account];
	}

	function availableBalance(address account) public view returns (uint256) {
		uint newlyAvailable = 0;
		Bag[] storage arr = _bags[account];
		for (uint i = 0; i < arr.length; i++) {
			uint256 currentWeek = (block.timestamp - arr[i].date) / 604800;
			uint256 lastUpdateWeek = (_bagsLastUpdated[account] > arr[i].date)
				? (_bagsLastUpdated[account] - arr[i].date) / 604800
				: 0;
			if (currentWeek > 3) currentWeek = 4;
			uint256 releases = currentWeek - lastUpdateWeek;
			if (releases == 0) continue;
			newlyAvailable += releases * (arr[i].amount / 4);
			if (currentWeek == 4) {
				newlyAvailable += arr[i].amount - 4 * (arr[i].amount / 4);
			}
		}
		return _availableBalance[account] + newlyAvailable;
	}

	function lockedBalance(address account) public view returns (uint256) {
		return balanceOf(account) - availableBalance(account);
	}

	function withdraw(uint256 amount) public nonReentrant {
		_processReleases(_msgSender());
		require(_availableBalance[_msgSender()] >= amount, "Not enough MOON available to withdraw.");
		IERC20(moonAddress).transfer(_msgSender(), amount);
		_availableBalance[_msgSender()] -= amount;
		_balance[_msgSender()] -= amount;
		_totalLocked -= amount;
	}

	function showBags(address account) public view returns (Bag[] memory) {
		return _bags[account];
	}

	function _processReleases(address account) private {
		uint removed = 0;
		Bag[] storage arr = _bags[account];
		for (uint i = 0; i < arr.length; i++) {
			if (removed > 0)
				arr[i - removed] = arr[i];
			uint256 currentWeek = (block.timestamp - arr[i].date) / 604800;
			uint256 lastUpdateWeek = (_bagsLastUpdated[account] > arr[i].date)
				? (_bagsLastUpdated[account] - arr[i].date) / 604800
				: 0;
			if (currentWeek > 3) currentWeek = 4;
			uint256 releases = currentWeek - lastUpdateWeek;
			if (releases == 0)
				continue;
			_availableBalance[account] += releases * (arr[i].amount / 4);
			if (currentWeek == 4) {
				_availableBalance[account] += arr[i].amount - 4 * (arr[i].amount / 4);
				removed++;
			}
		}
		for (uint i = 0; i < removed; i++)
			arr.pop();
		_bagsLastUpdated[account] = block.timestamp;
		_bags[account] = arr;
	}
}
