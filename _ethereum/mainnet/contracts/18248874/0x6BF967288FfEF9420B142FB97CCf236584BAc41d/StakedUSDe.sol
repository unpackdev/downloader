// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "./ERC4626.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./draft-IERC20Permit.sol";
import "./AccessControl.sol";
import "./Context.sol";
import "./IStakedUSDe.sol";

/**
 * @title StakedUSDe
 * @notice The StakedUSDe contract allows users to stake USDe tokens and earn a portion of protocol LST and perpetual yield that is allocated
 * to stakers by the Ethena DAO governance voted yield distribution algorithm.  The algorithm seeks to balance the stability of the protocol by funding
 * the protocol's insurance fund, DAO activities, and rewarding stakers with a portion of the protocol's yield.
 */
contract StakedUSDe is Context, AccessControl, Ownable, ReentrancyGuard, ERC20Permit, ERC4626, IStakedUSDe {
  using SafeERC20 for IERC20;

  /* ------------- CONSTANTS ------------- */

  /// @notice The role that is allowed to distribute rewards to this contract
  bytes32 public constant REWARDER_ROLE = keccak256('REWARDER_ROLE');
  // @notice The role which prevents an address to stake
  bytes32 public constant SOFT_RESTRICTED_STAKER_ROLE = keccak256('SOFT_RESTRICTED_STAKER_ROLE');
  // @notice The role which prevents an address to transfer, stake, or unstake. The owner of the contract can redirect address staking balance if an address is in full restricting mode.
  bytes32 public constant FULL_RESTRICTED_STAKER_ROLE = keccak256('FULL_RESTRICTED_STAKER_ROLE');
  /// @notice The vesting period of lastDistributionAmount over which it increasingly becomes available to stakers
  uint256 public constant VESTING_PERIOD = 8 hours;
  /// @notice Minimum non-zero shares amount to prevent donation attack
  uint256 public constant MIN_SHARES = 1 ether;

  /* ------------- STATE VARIABLES ------------- */

  /// @notice The amount of the last asset distribution from the controller contract into this
  /// contract + any unvested remainder at that time
  uint256 public vestingAmount;

  /// @notice The timestamp of the last asset distribution from the controller contract into this contract
  uint256 public lastDistributionTimestamp;

  /* ------------- ERRORS ------------- */

  /// @notice Error emitted shares or assets equal zero.
  error InvalidAmount();

  /// @notice Error emitted when owner attempts to rescue USDe tokens.
  error InvalidToken();

  /// @notice Error emitted when slippage is exceeded on a deposit or withdrawal
  error SlippageExceeded();

  /// @notice Error emitted when a small non-zero share amount remains, which risks donations attack
  error MinSharesViolation();

  /// @notice Error emitted when owner is not allowed to perform an operation
  error OperationNotAllowed();

  /* ------------- MODIFIERS ------------- */

  /// @notice ensure input amount nonzero
  modifier notZero(uint256 amount) {
    if (amount == 0) revert InvalidAmount();
    _;
  }

  /* ------------- CONSTRUCTOR ------------- */

  /**
   * @notice Constructor for StakedUSDe contract.
   * @param _asset The address of the USDe token.
   * @param initialRewarder The address of the initial rewarder.
   * @param owner The address of the admin role.
   *
   */
  constructor(
    IERC20 _asset,
    address initialRewarder,
    address owner
  ) ERC20('Staked USDe', 'stUSDe') ERC4626(_asset) ERC20Permit('stUSDe') {
    require(
      owner != address(0) && initialRewarder != address(0) && address(_asset) != address(0),
      'Zero address not valid'
    );

    _grantRole(DEFAULT_ADMIN_ROLE, owner);
    _grantRole(REWARDER_ROLE, initialRewarder);
    transferOwnership(owner);
  }

  /* ------------- EXTERNAL ------------- */

  /**
   * @notice Allows the owner to transfer rewards from the controller contract into this contract.
   * @param amount The amount of rewards to transfer.
   */
  function transferInRewards(uint256 amount) external nonReentrant onlyRole(REWARDER_ROLE) notZero(amount) {
    uint256 newVestingAmount = amount + getUnvestedAmount();

    vestingAmount = newVestingAmount;
    lastDistributionTimestamp = block.timestamp;
    // transfer assets from rewarder to this contract
    IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);

    emit RewardsReceived(amount, newVestingAmount);
  }

  /**
   * @notice Allows the owner to rescue tokens accidentally sent to the contract.
   * Note that the owner cannot rescue USDe tokens because they functionally sit here
   * and belong to stakers but can rescue staked USDe as they should never actually
   * sit in this contract and a staker may well transfer them here by accident.
   * @param token The token to be rescued.
   * @param amount The amount of tokens to be rescued.
   * @param to Where to send rescued tokens
   */
  function rescueTokens(address token, uint256 amount, address to) external onlyOwner {
    if (address(token) == asset()) revert InvalidToken();
    IERC20(token).safeTransfer(to, amount);
  }

  /**
   * @dev Burns the full restricted user amount and mints to the desired owner address.
   * @param from The address to burn the entire balance, with the FULL_RESTRICTED_STAKER_ROLE
   * @param to The address to mint the entire balance of "from" parameter.
   */
  function redistributeLockedAmount(address from, address to) external onlyOwner {
    if (hasRole(FULL_RESTRICTED_STAKER_ROLE, from) && !hasRole(FULL_RESTRICTED_STAKER_ROLE, to)) {
      uint256 amountToDistribute = balanceOf(from);
      _burn(from, amountToDistribute);
      _mint(to, amountToDistribute);

      emit LockedAmountRedistributed(from, to, amountToDistribute);
    } else {
      revert OperationNotAllowed();
    }
  }

  /* ------------- PUBLIC ------------- */

  /**
   * @notice Returns the amount of USDe tokens that are vested in the contract.
   */
  function totalAssets() public view override returns (uint256) {
    return IERC20(asset()).balanceOf(address(this)) - getUnvestedAmount();
  }

  /**
   * @notice Returns the amount of USDe tokens that are unvested in the contract.
   */
  function getUnvestedAmount() public view returns (uint256) {
    uint256 timeSinceLastDistribution = block.timestamp - lastDistributionTimestamp;

    if (timeSinceLastDistribution >= VESTING_PERIOD) {
      return 0;
    }

    return ((VESTING_PERIOD - timeSinceLastDistribution) * vestingAmount) / VESTING_PERIOD;
  }

  /// @dev Necessary because both ERC20 (from ERC20Permit) and ERC4626 declare decimals()
  function decimals() public pure override(ERC4626, ERC20) returns (uint8) {
    return 18;
  }

  /* ------------- INTERNAL ------------- */

  /// @notice ensures a small non-zero amount of shares does not remain, exposing to donation attack
  function _checkMinShares() internal view {
    uint256 _totalSupply = totalSupply();
    if (_totalSupply > 0 && _totalSupply < MIN_SHARES) revert MinSharesViolation();
  }

  /**
   * @dev Deposit/mint common workflow.
   * @param caller sender of assets
   * @param receiver where to send shares
   * @param assets assets to deposit
   * @param shares shares to mint
   */
  function _deposit(
    address caller,
    address receiver,
    uint256 assets,
    uint256 shares
  ) internal override nonReentrant notZero(assets) notZero(shares) {
    if (hasRole(SOFT_RESTRICTED_STAKER_ROLE, caller) || hasRole(SOFT_RESTRICTED_STAKER_ROLE, receiver)) {
      revert OperationNotAllowed();
    }
    super._deposit(caller, receiver, assets, shares);
    _checkMinShares();
  }

  /**
   * @dev Withdraw/redeem common workflow.
   * @param caller tx sender
   * @param receiver where to send assets
   * @param owner where to burn shares from
   * @param assets asset amount to transfer out
   * @param shares shares to burn
   */
  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  ) internal override nonReentrant notZero(assets) notZero(shares) {
    if (hasRole(FULL_RESTRICTED_STAKER_ROLE, caller) || hasRole(FULL_RESTRICTED_STAKER_ROLE, receiver)) {
      revert OperationNotAllowed();
    }

    super._withdraw(caller, receiver, owner, assets, shares);
    _checkMinShares();
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning. Disables transfers from or to of addresses with the FULL_RESTRICTED_STAKER_ROLE role.
   */

  function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
    if (hasRole(FULL_RESTRICTED_STAKER_ROLE, from) && to != address(0)) {
      revert OperationNotAllowed();
    }
    if (hasRole(FULL_RESTRICTED_STAKER_ROLE, to)) {
      revert OperationNotAllowed();
    }
  }

  /**
   * @dev Remove renounce role access from AccessControl, to prevent users to resign roles.
   */
  function renounceRole(bytes32, address) public virtual override {
    revert OperationNotAllowed();
  }
}
