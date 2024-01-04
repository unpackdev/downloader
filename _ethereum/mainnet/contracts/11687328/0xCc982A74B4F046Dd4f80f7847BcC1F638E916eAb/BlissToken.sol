// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";



contract Bliss is IERC20, OwnableUpgradeSafe {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;
  string private _name = "Bliss";
  string private _symbol = "BLISS";
  uint8 private _decimals = 18;

  // No fee list
  mapping(address => bool) public feelessAddr;

  // Transaction fee to buy wBTC with. This is divided by 10000.
  uint256 public txFee;

  // Fee handler contract (receives Bliss-fees and handles wBTC purchasing)
  address public feeHandler;

  // ETH LP unlock time. (3 months from inception)
  uint256 public LPUnlockingTime;

  // The base ETH/BLISS uniswap pair.
  IERC20 public UniswapETHPair;

  // The last amount of LP tokens in the bliss/eth pair
  uint256 lastTotalSupplyOfLPTokens;

  // Defer the construction of token to an initializer due to LGE.
  function initialize(
    address _lge,
    address _blissTreasury,
    address _feeHandler,
    address _uniPair
  ) external initializer {
    __Ownable_init();

    /** Token distribution - total 432,000 bliss **/

    // 230k for deflect deployer ( 220k pools, 10k share )
    _mint(_msgSender(), 230000 * 1e18);
    // 125k on LGE
    _mint(_lge, 125000 * 1e18);
    // 77k for Bliss treasury and comp fund
    _mint(_blissTreasury, 77000 * 1e18);
    // Transaction fee
    txFee = 500; // 5%
    /** ETH LP locked for 90 days */
    LPUnlockingTime = block.timestamp + 90 days;

    /**  No fees for: */

    // Token contract itself
    feelessAddr[address(this)] = true;

    // wBTC handler
    feelessAddr[_feeHandler] = true;

    feeHandler = _feeHandler;

    // LGE
    feelessAddr[_lge] = true;

    // Creator (deflect deployer in this case - toggled back when staking contracts are set up)
    feelessAddr[_msgSender()] = true;

    // Set the eth-pair address
    UniswapETHPair = IERC20(_uniPair);
  }

  /** @dev Change the fee handler location
   */
  function setFeeHandler(address _newAddr) external onlyOwner {
    feeHandler = _newAddr;
  }

  /** @dev Change the tx fee, 1000 = 10%
   */
  function setTxFee(uint256 _newFee) external onlyOwner {
    require(_newFee < 10000, "fee must be < 100%");
    txFee = _newFee;
  }

  /**
   * @dev Toggle no fees for @param _addr
   */
  function toggleFeeless(address _addr) public {
    require(_msgSender() == owner() || _msgSender() == feeHandler, "!sender");
    feelessAddr[_addr] = !feelessAddr[_addr];
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
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint256) {
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
  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address _owner, address spender) public view override returns (uint256) {
    return _allowances[_owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public override returns (bool) {
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
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
  ) internal {
    // Get fee from the hook - it will also forbid LP removals before lock period has finished.
    uint256 fee = _beforeTokenTransfer(sender, recipient, amount);
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    // This is 95% of transfer amount
    uint256 remainder = amount.sub(fee);

    // Regular transfer with fees deduced
    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(remainder);
    emit Transfer(sender, recipient, remainder);

    // Move fees to handler.
    if (fee > 0) {
      _balances[feeHandler] = _balances[feeHandler].add(fee);
      emit Transfer(sender, feeHandler, fee);
    }
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
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
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
    address _owner,
    address spender,
    uint256 amount
  ) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[_owner][spender] = amount;
    emit Approval(_owner, spender, amount);
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
   * @dev Bliss-token modification: Return the taxation amount for transfer.
   *
   */

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (uint256) {
    if (LPUnlockingTime >= block.timestamp) {
      // LP locking
      uint256 _LPSupplyOfPairTotal = UniswapETHPair.totalSupply();

      // Check that current supply is bigger or equal to the last supply.
      // This means liquidity additions and transfers can be made, but not removals.
      if (from == address(UniswapETHPair)) {
        require(lastTotalSupplyOfLPTokens <= _LPSupplyOfPairTotal, "Liquidity withdrawals forbidden");
      }
      // Sync the book-keeping variable to be up-to-date for the next transfer.
      lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
    }

    // No taxing when dealing with feeless
    if (feelessAddr[from] || feelessAddr[to]) {
      return 0;
    }
    // Standard taxing
    return amount.mul(txFee).div(10000);
  }
}
