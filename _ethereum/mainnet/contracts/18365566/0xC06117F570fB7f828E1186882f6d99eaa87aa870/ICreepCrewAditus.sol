// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./IERC721Upgradeable.sol";

interface ICreepCrewAditus is IERC721Upgradeable{
	
	function mint(uint256 amount, address to) external;
	function totalSupply() external view returns (uint256);
	
}
