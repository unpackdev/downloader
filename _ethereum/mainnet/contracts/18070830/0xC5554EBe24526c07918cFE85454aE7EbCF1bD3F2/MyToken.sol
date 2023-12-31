// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Context.sol";

contract IKUNToken is Context, ERC20 {
    constructor() ERC20("IKUN Token", "IKUN") {
        // Total supply
        _mint(address(0x647470e53D8Aa3394b4D7FC07Db0792B0c3FEf47), 1000000000000);
    }

    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, deducting from
     * the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `value`.
     */
    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}