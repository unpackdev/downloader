// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISpaceMilk {
	function burn(address _from, uint256 _collection, uint256 _amount) external;
    function updateReward(address _from, uint256 _fromRate, address _to, uint256 _toRate, uint256 _collection) external;
    function fullRewardUpdate(address _user, uint256 _rate, uint256 _collection) external;
    function getReward(address _to, uint256 _collection) external;
}

