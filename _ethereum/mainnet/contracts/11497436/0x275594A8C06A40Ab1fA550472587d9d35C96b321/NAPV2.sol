// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

import "./Fees.sol";

/**
 * @title NAP V2
 * @author ZZZ.FINANCE
 * @dev Newer version of the token supporting fees on transfer.
 *
 * Different fees are applied for different targets and they will be distributed to treasury and/or feeReceivers.
 */

contract NAPV2 is AccessControlUpgradeSafe, IERC20 {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  using Fees for uint256;

  struct FeeReceiver {
    address addr;
    uint256 percentage; //  10000 == 100%
  }

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public constant TOKEN_CAP = 20000000 * 1e18;
  uint256 private _totalSupply;

  string private _name = "NAP V2";
  string private _symbol = "NAPV2";
  uint8 private _decimals = 18;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  // Total network tx fee (max 5%)
  uint256 public txFee;
  // Total selling fee (max 10%)
  uint256 public sellTxFee;

  // Treasury fee
  uint256 public treasuryPercentage;
  address public treasury;

  // Blacklisted account total fees
  uint256 public blackListTxFee;
  uint256 public blackListSellTxFee;

  // Vault addresses and fees
  FeeReceiver[] public feeReceivers;
  uint256 totalFeeReceiverFees;

  // Skip fee deduction for these addresses
  mapping(address => bool) public skipFees;

  // Blacklisting data
  mapping(address => bool) public blacklistedAddr;
  mapping(address => bool) public sellTargets;

  // Migration variables
  mapping(address => uint256) public swapCooldown;
  uint256 public migrationCutoff;
  IERC20 public V1;
  bool paused;

  event AddressBlacklisted(address blacklistedAddress);
  event blackListTxFeeChange(uint256 newBlackListTransferFee, uint256 newblackListSellTxFee);
  event TokenSwapped(uint256 amount);

  function init(
    uint256 _txFee,
    uint256 _treasuryPercentage,
    uint256 _sellTxFee,
    uint256 _blackListTxFee,
    uint256 _blackListSellTxFee,
    address _V1,
    address _treasury
  ) external initializer {
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    V1 = IERC20(_V1);
    txFee = _txFee;
    sellTxFee = _sellTxFee;
    blackListTxFee = _blackListTxFee;
    blackListSellTxFee = _blackListSellTxFee;
    treasuryPercentage = _treasuryPercentage;
    treasury = _treasury;
    migrationCutoff = 0; // 0 = Can transfer, 1 = Migration Cutoff

    // NAP migration pool
    skipFees[0x2F867Bf441D62584B3F0a84828C2e62dAC9fb4e6] = true;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  // Toggle an address to not have fees applied to it's transfers
  function toggleSellTarget(address _address) external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Only governance");
    sellTargets[_address] = !sellTargets[_address];
  }

  // Toggle an address to not have fees applied to it's transfers
  function toggleFeeSkippingFor(address _address) external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Only governance");
    skipFees[_address] = !skipFees[_address];
  }

  /** @dev fee structure adjustment functions */
  // Set the default transfer fee
  function setTransferFees(uint256 _transferFee, uint256 _sellFee) external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Only governance");
    require(_transferFee >= 0 && _transferFee <= 500, "Fee clamp 0-5%");
    require(_sellFee >= 0 && _sellFee <= 1000, "Sell fee clamp 0-10%");
    txFee = _transferFee;
    sellTxFee = _sellFee;
  }

  function toggleBlacklistedAddress(address _blacklistAddress) external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Sender not gov or admin");
    blacklistedAddr[_blacklistAddress] = !blacklistedAddr[_blacklistAddress];
    emit AddressBlacklisted(_blacklistAddress);
  }

  function adjustBlacklistTxFees(uint256 _newBlacklistTxFee, uint256 _newBlacklistSellTxFee) external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Sender not gov or admin");
    blackListTxFee = _newBlacklistTxFee;
    blackListSellTxFee = _newBlacklistSellTxFee;
    emit blackListTxFeeChange(_newBlacklistTxFee, _newBlacklistSellTxFee);
  }

  function setTreasuryPercentage(uint256 _newTreasuryPercentage) external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Only governance");
    require(_newTreasuryPercentage.add(totalFeeReceiverFees) <= 10000, "Cannot be more than 100%");
    treasuryPercentage = _newTreasuryPercentage;
  }

  function setFeeReceiver(FeeReceiver memory _feeReceiver) external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Only governance");
    bool add;
    if (feeReceivers.length > 0) {
      for (uint256 i; i < feeReceivers.length; i++) {
        if (feeReceivers[i].addr == _feeReceiver.addr) {
          require(
            totalFeeReceiverFees.sub(feeReceivers[i].percentage).add(_feeReceiver.percentage).add(treasuryPercentage) <= 10000,
            "Cannot be more than 100%"
          );
          totalFeeReceiverFees = totalFeeReceiverFees.sub(feeReceivers[i].percentage).add(_feeReceiver.percentage);
          feeReceivers[i] = _feeReceiver;
          add = false;
          break;
        } else {
          add = true;
        }
      }
    } else {
      add = true;
    }
    if (add) {
      feeReceivers.push(_feeReceiver);
      totalFeeReceiverFees = totalFeeReceiverFees.add(_feeReceiver.percentage);
    }
  }

  function removeVault(address _feeReceiver) external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Only governance");
    for (uint256 i; i < feeReceivers.length; i++) {
      if (feeReceivers[i].addr == _feeReceiver) {
        totalFeeReceiverFees = totalFeeReceiverFees.sub(feeReceivers[i].percentage);
        feeReceivers[i] = feeReceivers[feeReceivers.length - 1];
        feeReceivers.pop();
        break;
      }
    }
  }

  /**
   * Requirements:
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
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

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  // Add pausability if required
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual returns (bool) {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    uint256 fee = _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

    // Deal with fees
    if (fee > 0) handleFee(fee);

    _balances[recipient] = _balances[recipient].add(amount.sub(fee));
    emit Transfer(sender, recipient, amount.sub(fee));
    return true;
  }

  function handleFee(uint256 _fee) private {
    _balances[treasury] = _balances[treasury].add(_fee.mul(treasuryPercentage).div(10000));
    if (feeReceivers.length > 0) {
      for (uint256 i; i < feeReceivers.length; i++) {
        _balances[feeReceivers[i].addr] = _balances[feeReceivers[i].addr].add(_fee.mul(feeReceivers[i].percentage).div(10000));
      }
    }
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   * It's capped to MAX_CAP by _beforeTokenTransfer.
   * Requirements
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) private {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /** @dev Swaps the old V1 tokens, sending them to burn address and minting the caller the V2 ones. */
  function swapV1toV2() external {
    require(migrationCutoff == 0, "Migration to V2 has already been completed");
    uint256 V1Balance = V1.balanceOf(_msgSender());
    require(V1Balance > 0, "No ZZZs to swap");
    require(V1.transferFrom(_msgSender(), 0x000000000000000000000000000000000000dEaD, V1Balance), "No allowance?");

    swapCooldown[_msgSender()] = block.timestamp + 1 days;
    _mint(_msgSender(), V1Balance);

    emit TokenSwapped(V1Balance);
  }

  function cutoffV2Migration() external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Sender not admin");
    require(migrationCutoff == 0, "Migration has already been cut off");
    migrationCutoff++;
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
  ) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  // Use the hook for returning fee values
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal view returns (uint256) {
    if (from == address(0)) {
      require(totalSupply().add(amount) <= TOKEN_CAP, "All tokens minted");
      return 0;
    }

    if (from == 0x9527dcf941D474A52B74eed5E041c2dBa2eEe1CA) return 0;

    require(
      !paused ||
        (hasRole(DEFAULT_ADMIN_ROLE, from) || hasRole(DEFAULT_ADMIN_ROLE, to)) ||
        (hasRole(GOVERNANCE_ROLE, from) || hasRole(DEFAULT_ADMIN_ROLE, to)),
      "Token transfers paused!"
    );

    require(swapCooldown[from] <= block.timestamp, "Swap cooldown");

    // Deduct the fees for different targets
    if (blacklistedAddr[from] && sellTargets[to]) {
      return amount.getFee(blackListSellTxFee);
    } else if (blacklistedAddr[from] || blacklistedAddr[to]) {
      return amount.getFee(blackListTxFee);
    } else if (sellTargets[to]) {
      return amount.getFee(sellTxFee);
    } else if (skipFees[to] || skipFees[from]) {
      return 0;
    } else {
      return amount.getFee(txFee);
    }
  }

  function mint(address account, uint256 amount) public {
    require(hasRole(MINTER_ROLE, _msgSender()), "!minter");
    _mint(account, amount);
  }

  function togglePause() external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()));
    paused = !paused;
  }
}
