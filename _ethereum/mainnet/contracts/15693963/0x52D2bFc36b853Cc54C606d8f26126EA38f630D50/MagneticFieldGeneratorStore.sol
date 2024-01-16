// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IMagneticFieldGeneratorStore.sol";

contract MagneticFieldGeneratorStore is IMagneticFieldGeneratorStore, Ownable
{
	mapping(uint256 => mapping(address => UserInfo)) private _userInfo;
	PoolInfo[] private _poolInfo;

	function newPoolInfo(PoolInfo memory pi) override external onlyOwner
	{
		_poolInfo.push(pi);
	}

	function deletePoolInfo(uint256 pid) override external onlyOwner
	{
		require(_poolInfo[pid].allocPoint == 0, "MFGS: Pool is active");
		_poolInfo[pid] = _poolInfo[_poolInfo.length - 1];
		_poolInfo.pop();
	}

	function updateUserInfo(uint256 pid, address user, UserInfo memory ui) override external onlyOwner
	{
		_userInfo[pid][user] = ui;
	}

	function updatePoolInfo(uint256 pid, PoolInfo memory pi) override external onlyOwner
	{
		_poolInfo[pid] = pi;
	}


	function getPoolInfo(uint256 pid) override external view returns (PoolInfo memory)
	{
		return _poolInfo[pid];
	}

	function getPoolLength() override external view returns (uint256)
	{
		return _poolInfo.length;
	}

	function getUserInfo(uint256 pid, address user) override external view returns (UserInfo memory)
	{
		return _userInfo[pid][user];
	}

	/// @notice Leaves the contract without owner. Can only be called by the current owner.
	/// This is a dangerous call be aware of the consequences
	function renounceOwnership() public override(IOwnable, Ownable)
	{
		Ownable.renounceOwnership();
	}

	/// @notice Returns the address of the current owner.
	function owner() public view override(IOwnable, Ownable) returns (address)
	{
		return Ownable.owner();
	}
}
