//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";

contract ERC20Rebase is IERC20 {
    using SafeMath for uint256;

    uint256 internal _totalSupply;
    uint256 internal _gonsPerFragment = 1e6;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    function gonsPerFragment() public view virtual returns (uint256) {
        return _gonsPerFragment;
    }

    function gonsDecimals() public view virtual returns (uint256) {
        return 6;
    }

    function gonsPercision() public view virtual returns (uint256) {
        return 10**gonsDecimals();
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply.mul(gonsPerFragment()).div(gonsPercision());
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account].mul(gonsPerFragment()).div(gonsPercision());
    }

    function underlyingBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`s tokens of at least
     * `amount`.
     *
     * NOTE: The `spender i.e msg.sender` and the `owner` both should not be blacklisted.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ARTH.usd: transfer amount exceeds allowance"
            )
        );

        return true;
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
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
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
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ARTH.usd: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     *
     * NOTE: The `sender` should not be blacklisted.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 value
    ) internal {
        // get amount in underlying
        uint256 gonValues = value.div(gonsPerFragment()).mul(gonsPercision());

        // sub from balance of sender
        _balances[sender] = _balances[sender].sub(gonValues);

        // add to balance of receiver
        _balances[recipient] = _balances[recipient].add(gonValues);
        emit Transfer(sender, recipient, value);
    }

    function _mint(address account, uint256 gonValues) internal {
        require(account != address(0), "ARTH.usd: mint to the zero address");

        uint256 amount = gonValues.mul(gonsPerFragment()).div(gonsPercision());

        _totalSupply = _totalSupply.add(gonValues);
        _balances[account] = _balances[account].add(gonValues);

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 gonValues) internal {
        require(account != address(0), "ARTH.usd: burn from the zero address");

        uint256 amount = gonValues.mul(gonsPerFragment()).div(gonsPercision());

        _balances[account] = _balances[account].sub(
            gonValues,
            "ARTH.usd: burn amount exceeds balance"
        );

        _totalSupply = _totalSupply.sub(gonValues);

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ARTH: approve from zero");
        require(spender != address(0), "ARTH: approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
