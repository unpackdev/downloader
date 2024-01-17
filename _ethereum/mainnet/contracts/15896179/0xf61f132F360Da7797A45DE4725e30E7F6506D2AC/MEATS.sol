// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MEATS is ERC20, ERC20Permit, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) internal _blocklisted;

    event Blocklisted(address indexed account);
    event UnBlocklisted(address indexed account);

    error Blocklisted_account();

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(uint256 _initialSupply, address _receiver) ERC20("MEATS Token", "MTS") ERC20Permit("MEATS Token") {
        _mint(_receiver, _initialSupply);
    }

    /**
     * @dev Adds `_account` to the blocklist.
     *
     */
    function blockList(address _account) external onlyOwner {
        _blocklisted[_account] = true;
        emit Blocklisted(_account);
    }

    /**
     * @dev Removes `_account` from the blocklist.
     *
     */
    function unblockList(address _account) external onlyOwner {
        _blocklisted[_account] = false;
        emit UnBlocklisted(_account);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller should not be blocklisted
     * - `to` should not be blocklisted
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        _notBlocklisted(_msgSender());
        _notBlocklisted(to);
        return super.transfer(to, amount);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - the caller should not be blocklisted
     * - `spender` should not be blocklisted
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _notBlocklisted(_msgSender());
        _notBlocklisted(spender);
        return super.approve(spender, amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - the caller should not be blocklisted
     * - `from` should not be blocklisted
     * - `to` should not be blocklisted
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _notBlocklisted(_msgSender());
        _notBlocklisted(from);
        _notBlocklisted(to);
        return super.transferFrom(from, to, amount);
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - the caller should not be blocklisted
     * - `spender` should not be blocklisted
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _notBlocklisted(_msgSender());
        _notBlocklisted(spender);
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - the caller should not be blocklisted
     * - `spender` should not be blocklisted
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        _notBlocklisted(_msgSender());
        _notBlocklisted(spender);
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller should not be blocklisted
     */
    function burn(uint256 amount) public override {
        _notBlocklisted(_msgSender());
        super.burn(amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller should not be blocklisted
     * - `account` should not be blocklisted
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public override {
        _notBlocklisted(_msgSender());
        _notBlocklisted(account);
        super.burnFrom(account, amount);
    }

    /**
     * @dev Checks if `account` is blocklisted
     */
    function isBlockListed(address account) external view returns (bool) {
        return _blocklisted[account];
    }

    /**
     * @dev Recovers deposited tokens
     */
    function recoverFunds(address _token, address _receiver) external onlyOwner {
        IERC20(_token).safeTransfer(_receiver, IERC20(_token).balanceOf(address(this)));
    }

    function _notBlocklisted(address _account) internal view {
        if (_blocklisted[_account]) revert Blocklisted_account();
    }
}
