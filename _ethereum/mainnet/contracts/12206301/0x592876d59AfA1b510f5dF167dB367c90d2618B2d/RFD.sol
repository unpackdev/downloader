// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./NFTStaking.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract RFD is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "Reflect Dao";
    string private _symbol = "RFD";
    uint256 private _total = 2 * 10**6 * 10**6;

    mapping(address => bool) private _excluded;
    mapping(address => bool) private _whitelisted;

    address _lpToken;
    IERC1155 _nftToken;
    IERC20 _usdcToken;

    NFTStaking _rewardDistributor;

    uint256 public vipTokenId = 1;

    uint256 _lastRebaseTime;
    uint256 priceFactor = 10**6;

    event TransferFee(address to, uint256 amount);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(IERC1155 _nftAddr, IERC20 _usdcAddr) {
        _nftToken = _nftAddr;
        _usdcToken = _usdcAddr;
        _lastRebaseTime = block.timestamp;
        _mint(_msgSender(), _total);
        emit Transfer(address(0), _msgSender(), _total);
    }

    modifier onlyExcluded() {
        require(
            _excluded[_msgSender()] ||
                _nftToken.balanceOf(_msgSender(), vipTokenId) > 0 ||
                _rewardDistributor.isStakeHolder(_msgSender()),
            "Not excluded"
        );
        _;
    }

    /**
     * @dev Updates NFT Token Contract
     */
    function updateNFTToken(IERC1155 _nftAddr) external onlyOwner {
        _nftToken = _nftAddr;
    }

    /**
     * @dev set the account to be excluded or included
     */
    function setExcluded(address account, bool _status) external onlyOwner {
        _excluded[account] = _status;
    }

    /**
     * @dev set the account to be whitelisted or not
     */
    function setWhitelisted(address account, bool _status) external onlyOwner {
        _whitelisted[account] = _status;
    }

    /**
     * @dev return if account is excluded
     */
    function isExcluded(address account) public view returns (bool) {
        return
            _excluded[account] ||
            _nftToken.balanceOf(account, vipTokenId) > 0 ||
            _rewardDistributor.isStakeHolder(account);
    }

    /**
     * @dev return if account is excluded
     */
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisted[account];
    }

    function setLpToken(address _lpAddr) public onlyOwner {
        _lpToken = _lpAddr;
    }

    function setNFTToken(IERC1155 _nftAddr) public onlyOwner {
        _nftToken = _nftAddr;
    }

    function setDistributor(NFTStaking _distAddr) public onlyOwner {
        _rewardDistributor = _distAddr;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 6;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account].mul(priceFactor).div(10**6);
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
        _transfer(_msgSender(), recipient, amount);
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
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

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
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];

        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        uint256 _tFee = amount.mul(3).div(100);
        uint256 _rAmount = amount.sub(_tFee);

        if (isExcluded(recipient) || isWhitelisted(sender)) {
            _balances[sender] = senderBalance.sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
        } else {
            _balances[sender] = senderBalance.sub(amount);
            _balances[recipient] = _balances[recipient].add(_rAmount);

            _balances[address(_rewardDistributor)] = _balances[
                address(_rewardDistributor)
            ]
                .add(_tFee);
            emit TransferFee(address(_rewardDistributor), _tFee);
        }

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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

    function rebase() public onlyExcluded {
        require(
            block.timestamp >= _lastRebaseTime + 8 hours,
            "Not available at this time"
        );
        uint256 usdcBalance = _usdcToken.balanceOf(_lpToken);
        uint256 tokenBalance = balanceOf(_lpToken);

        if (usdcBalance > tokenBalance) {
            priceFactor = priceFactor
                .mul(10**6 + 2 * 10**4)
                .div(10**6)
                .mul(tokenBalance)
                .div(usdcBalance);
            _lastRebaseTime = block.timestamp;
        } else if (usdcBalance < tokenBalance) {
            priceFactor = priceFactor
                .mul(10**6 - 2 * 10**4)
                .div(10**6)
                .mul(tokenBalance)
                .div(usdcBalance);
            _lastRebaseTime = block.timestamp;
        }
    }
}
