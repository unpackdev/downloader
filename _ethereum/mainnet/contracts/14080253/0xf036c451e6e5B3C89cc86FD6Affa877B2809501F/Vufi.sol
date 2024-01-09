// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./ERC20Permit.sol";
import "./AccessControl.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IVufi.sol";

contract Vufi is Context, AccessControl, ERC20Burnable, ERC20Permit, IVufi {
  using SafeMath for uint256;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor(address admin, address minter) ERC20Permit("Vufi.finance") ERC20("Vufi.finance", "VUFI") {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(MINTER_ROLE, minter);
  }

  /**
    * @dev Creates `amount` new tokens for `to`.
    *
    * See {ERC20-_mint}.
    *
    * Requirements:
    *
    * - the caller must have the `MINTER_ROLE`.
  */
  function mint(address to, uint256 amount) public override virtual {
    require(hasRole(MINTER_ROLE, _msgSender()), "Vufi: must have minter role to mint");
    _mint(to, amount);
  }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
  */
  function burn(uint256 amount) public override(ERC20Burnable, IVufi) virtual {
    super._burn(_msgSender(), amount);
  }

  /**
    * @dev Destroys `amount` tokens from `account`, deducting from the caller's
    * allowance.
    *
    * See {ERC20-_burn} and {ERC20-allowance}.
    *
    * Requirements:
    *
    * - the caller must have allowance for ``accounts``'s tokens of at least
    * `amount`.
  */
  function burnFrom(address account, uint256 amount) public override(ERC20Burnable, IVufi) virtual {
    uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "Vufi: burn amount exceeds allowance");

    super._approve(account, _msgSender(), decreasedAllowance);
    super._burn(account, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20) {
    super._beforeTokenTransfer(from, to, amount);
  }

  /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
  */
  function transferFrom(address sender, address recipient, uint256 amount) public
  override(ERC20, IERC20) returns (bool) {
    _transfer(sender, recipient, amount);
    if (allowance(sender, _msgSender()) != uint256(-1)) {
      _approve(
        sender,
        _msgSender(),
        allowance(sender, _msgSender()).sub(amount, "Vufi: transfer amount exceeds allowance"));
    }
    return true;
  }
}
