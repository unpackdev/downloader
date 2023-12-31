// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

/**
 */
contract ERC20Reflections is Context, IERC20, IERC20Metadata, Ownable {
    uint256 private constant MAX = ~uint256(0);

    mapping(address => uint256) private _rBalances; // balances in r-space
    mapping(address => uint256) private _tBalances; // balances in t-space

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromReward;
    mapping(address => uint256) public reflections;

    uint256 private _rTotalSupply; // total supply in r-space
    uint256 private _tTotalSupply; // total supply in t-space
    string private _name;
    string private _symbol;
    address[] private _excludedFromReward;

    uint256 public txFee = 500; // 500 => 5%
    uint256 public accumulatedFees;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 txFee_,
        uint256 totalSupply_,
        address owner_,
        address supplyRecipient_
    ) {
        _name = name_;
        _symbol = symbol_;
        _tTotalSupply = totalSupply_;
        txFee = txFee_;
        excludeFromFee(supplyRecipient_);
        excludeFromFee(owner_);
        excludeFromFee(address(0));
        _mint(supplyRecipient_, totalSupply_); // for deployer use msg.sender
        _transferOwnership(owner_);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tTotalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        uint256 rate = _conversionRate();
        return _rBalances[account] / rate;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
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
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    // add address to the blacklist
    function addToBlacklist(address account) public onlyOwner {
        isBlacklisted[account] = true;
    }

    // remove address from the blacklist
    function removeFromBlacklist(address account) public onlyOwner {
        isBlacklisted[account] = false;
    }

    function setTransactionFee(uint256 _txFee) public onlyOwner {
        txFee = _txFee;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!isExcludedFromReward[account], "Address already excluded");
        require(_excludedFromReward.length < 100, "Excluded list is too long");
        // TODO
        if (_rBalances[account] > 0) {
            uint256 rate = _conversionRate();
            _tBalances[account] = _rBalances[account] / rate;
        }
        isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[
                    _excludedFromReward.length - 1
                ];
                _tBalances[account] = 0;
                isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    function numExcludedFromReward() public view returns (uint256) {
        return _excludedFromReward.length;
    }

    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function _conversionRate() private view returns (uint256) {
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _tTotalSupply;
        // TODO
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            rSupply = rSupply - _rBalances[_excludedFromReward[i]];
            tSupply = tSupply - _tBalances[_excludedFromReward[i]];
        }
        if (rSupply < _rTotalSupply / _tTotalSupply) {
            rSupply = _rTotalSupply;
            tSupply = _tTotalSupply;
        }
        uint256 rate = rSupply / tSupply;
        return rate;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            !isBlacklisted[from] && !isBlacklisted[to],
            "This address is blacklisted."
        );

        _beforeTokenTransfer(from, to, amount);

        uint256 _txFee;
        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            _txFee = 0;
        } else {
            _txFee = txFee;
        }

        // calc t-values
        uint256 tAmount = amount;
        uint256 tTxFee = (tAmount * _txFee) / 10000;
        uint256 tTransferAmount = tAmount - tTxFee;

        // calc r-values
        uint256 rate = _conversionRate();
        uint256 rTxFee = tTxFee * rate;
        uint256 rAmount = tAmount * rate;
        uint256 rTransferAmount = rAmount - rTxFee;

        // check balances
        uint256 rFromBalance = _rBalances[from];
        uint256 tFromBalance = _tBalances[from];

        if (isExcludedFromReward[from]) {
            require(
                tFromBalance >= tAmount,
                "ERC20: transfer amount exceeds balance"
            );
        } else {
            require(
                rFromBalance >= rAmount,
                "ERC20: transfer amount exceeds balance"
            );
        }

        // Overflow not possible: the sum of all balances is capped by
        // rTotalSupply and tTotalSupply, and the sum is preserved by
        // decrementing then incrementing.
        unchecked {
            // udpate balances in r-space
            _rBalances[from] = rFromBalance - rAmount;
            _rBalances[to] += rTransferAmount;

            // update balances in t-space
            if (isExcludedFromReward[from] && isExcludedFromReward[to]) {
                _tBalances[from] = tFromBalance - tAmount;
                _tBalances[to] += tTransferAmount;
            } else if (
                isExcludedFromReward[from] && !isExcludedFromReward[to]
            ) {
                _tBalances[from] = tFromBalance - tAmount;
            } else if (
                !isExcludedFromReward[from] && isExcludedFromReward[to]
            ) {
                // can this overflow?
                _tBalances[to] += tTransferAmount;
            }

            // reflect fee
            // can never go below zero because rTxFee percentage of
            // _rTotalSupply
            _rTotalSupply = _rTotalSupply - rTxFee;
            accumulatedFees += tTxFee;
        }

        emit Transfer(from, to, tTransferAmount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _rTotalSupply += (MAX - (MAX % amount));
        unchecked {
            // Overflow not possible: balance + amount is at most rTotalSupply + amount, which is checked above.
            _rBalances[account] += _rTotalSupply;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
