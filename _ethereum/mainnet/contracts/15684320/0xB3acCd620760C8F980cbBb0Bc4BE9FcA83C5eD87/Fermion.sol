// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IFermion.sol";

/**
* @dev Implementation of the {IFermion} interface.
*/
contract Fermion is Ownable, ERC20Burnable, IFermion
{
	uint256 private constant _MAX_SUPPLY = (1000000000 * (10**18));

	constructor() ERC20Burnable("Fermion", "EXOFI")
	{
		_mint(owner(), (_MAX_SUPPLY * 4) / 10); // 40%
	}

	/// @notice Creates `amount` token to `to`. Must only be called by the owner (MagneticFieldGenerator).
	function mint(address to, uint256 amount) override public onlyOwner
	{
		require(totalSupply() < _MAX_SUPPLY, "Fermion: Max supply reached");
		_mint(to, amount);
	}
}
