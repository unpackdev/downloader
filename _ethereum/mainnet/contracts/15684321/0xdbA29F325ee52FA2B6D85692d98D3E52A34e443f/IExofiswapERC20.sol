// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20AltApprove.sol";
import "./IERC20Metadata.sol";

interface IExofiswapERC20 is IERC20AltApprove, IERC20Metadata
{
	// Functions as described in EIP 2612
	function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
	function nonces(address owner) external view returns (uint256);
	function DOMAIN_SEPARATOR() external view returns (bytes32); // solhint-disable-line func-name-mixedcase
	function PERMIT_TYPEHASH() external pure returns (bytes32); //solhint-disable-line func-name-mixedcase
}