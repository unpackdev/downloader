// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISpaceMilk {
    function updateUserTimeOnMint(address _user, uint256 _collection) external;
	function burn(address _from, uint256 _collection, uint256 _amount) external;
    function updateReward(address _from, address _to, uint256 _collection) external;
    function getReward(address _to, uint256 _collection) external;
}

