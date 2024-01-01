// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface i_ls_token {
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	function mint(address to, uint256 amount) external;

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;

	function balanceOf(address account) external view returns (uint256);

	function totalSupply() external view returns (uint256);
}
