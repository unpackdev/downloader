pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Mintable.sol";
import "./ERC20Pausable.sol";

contract WholeEarthCoinToken is ERC20, ERC20Burnable, ERC20Mintable, ERC20Pausable {
  string private _name = "WholeEarthCoin";
	string private _symbol = "WEC";
	uint8 private _decimals = 18;

  constructor(address _initialAddress, uint256 totalSupply) public {
		_mint(_initialAddress, totalSupply);
	}

  /**
	 * @dev Returns the name of the token.
	 */
	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() public view returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei.
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() public view returns (uint8) {
		return _decimals;
	}
}
