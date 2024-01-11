// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IClaimable.sol";

interface ISerum is IClaimable {
	function mint(address _to, uint256 _amount) external;
	function burn(address _from, uint256 _amount) external;
}