// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IPlanet.sol";

contract Planet is Ownable, ERC20, IPlanet
{
	IERC20Metadata private immutable _token;

	constructor(IERC20Metadata tokenInit) ERC20("Planet", "GRAVITY") Ownable()
	{
		_token = tokenInit;
	}

	// Locks Tokens and mints PlanetTokens.
	function enter(uint256 amount, address to) override external onlyOwner
	{
		// Mint PlanetToken at 1:1 ratio
		_mint(to, amount);
		// Lock Token in the contract
		SafeERC20.safeTransferFrom(_token, _msgSender(), address(this), amount);
		emit Enter(_msgSender(), amount, to);
	}

	// this low-level function should be called from a contract which performs important safety checks
	function leave(uint256 amount, address to) override external onlyOwner
	{
		// Burn PlanetToken at 1:1 ratio
		_burn(_msgSender(), amount);
		// Transfer Token
		SafeERC20.safeTransfer(_token, to, amount);
		emit Leave(_msgSender(), amount, to);
	}

	function token() override external view returns (IERC20Metadata)
	{
		return _token;
	}

	function name() override(ERC20, IERC20Metadata) public view virtual returns (string memory)
	{
		return string(abi.encodePacked(super.name(), " ", _token.symbol()));
	}
}
