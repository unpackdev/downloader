// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./OwnableUpgradeable.sol";
import "./IVestingEscrowFactory.sol";
import "./IDelegateRegistry.sol";
import "./IStakedLyra.sol";

/**
 * @title VestingEscrow
 * @author Lyra
 * @dev Sets a vesting schedule on the Lyra token for a recipient. After the cliff date, tokens vest linearly.
 * Holds functionality to interact with the safety module.
 * The recipient receives the voting power of the locked tokens to use them in governance.
 * The owner holds the power of stopping the vesting, reclaiming the tokens amount not vested.
 */
contract VestingEscrow is OwnableUpgradeable {
  using SafeMath for uint256;

  IERC20 public immutable token;
  IDelegateRegistry public immutable delegateRegistry;

  IVestingEscrowFactory public factory;

  address public recipient;
  uint256 public vestingAmount;
  uint256 public vestingBegin;
  uint256 public vestingCliff;
  uint256 public vestingEnd;

  uint256 public lastUpdate;

  event Claimed(address token, uint256 amount, address claimer, address recipient);
  event Removed(address token, uint256 amount);

  /**
   * @dev Throws if called by any account other than the `recipient`.
   */
  modifier onlyRecipient() {
    require(msg.sender == recipient, "not authorized");
    _;
  }

  /**
   * @dev Stores the `token` and the `delegateRegistry`.
   *
   * @param token_ The address of the ERC20 to be distributed
   * @param delegateRegistry_ The address of the voting power delegation registry
   */
  constructor(address token_, address delegateRegistry_) {
    token = IERC20(token_);
    delegateRegistry = IDelegateRegistry(delegateRegistry_);
  }

  /**
   * @dev Initializes the owner and vest parameters
   * @param recipient_ The address of the recipient that will be receiving the tokens
   * @param vestingAmount_ Amount of tokens being vested for `recipient`
   * @param vestingBegin_ Epoch time when tokens begin to vest
   * @param vestingCliff_ Duration after which the first portion vests
   * @param vestingEnd_ Epoch Time until all the amount should be vested
   * @return Bool indicating the correct initialization
   */
  function initialize(
    address recipient_,
    uint256 vestingAmount_,
    uint256 vestingBegin_,
    uint256 vestingCliff_,
    uint256 vestingEnd_
  ) external initializer returns (bool) {
    require(vestingBegin_ >= IVestingEscrowFactory(msg.sender).deploymentTimestamp(), "vesting begin too early");
    require(vestingCliff_ >= vestingBegin_, "cliff is too early");
    require(vestingEnd_ >= vestingCliff_, "end is too early");
    require(vestingEnd_ > vestingBegin_, "end should be bigger than start");

    __Ownable_init_unchained();

    recipient = recipient_;

    vestingAmount = vestingAmount_;
    vestingBegin = vestingBegin_;
    vestingCliff = vestingCliff_;
    vestingEnd = vestingEnd_;

    lastUpdate = vestingBegin;
    factory = IVestingEscrowFactory(msg.sender);

    // Delegate voting power to recipient
    delegateRegistry.setDelegate("", recipient_);

    return true;
  }

  /**
   * @dev Claim the vested tokens for the recipient. Anyone can call this method.
   * If there are tokens staked in the safety module, the staked token representation will have priority to be
   * transferred first.
   * Unclaimed SafetyModule rewards will remain assigned to this contract after executing this function.
   */
  function claim() external {
    require(block.timestamp >= vestingCliff, "not time yet");

    IStakedLyra stakedToken = factory.stakedToken();

    uint256 amount;
    uint256 stAmount;

    if (block.timestamp >= vestingEnd) {
      amount = _tokenBalance(token);
      stAmount = _stakedTokenBalance(stakedToken);
    } else {
      amount = _getClaimAmount();
      stAmount = Math.min(amount, _stakedTokenBalance(stakedToken));
      amount = amount.sub(stAmount);

      lastUpdate = block.timestamp;
    }

    if (stAmount > 0) {
      _transferAsset(stakedToken, recipient, stAmount);
      emit Claimed(address(stakedToken), stAmount, msg.sender, recipient);
    }

    if (amount > 0) {
      _transferAsset(token, recipient, amount);
      emit Claimed(address(token), amount, msg.sender, recipient);
    }
  }

  /**
   * @dev Cancels the vesting and withdraws the amount not vested. Only the owner can call this method.
   * Unclaimed SafetyModule rewards will remain assigned to this contract after executing this function.
   */
  function cancelVesting() external onlyOwner {
    uint256 vested = _getClaimAmount();

    // update end date so the recipient can claim the remaining token balance
    // instead of calculating the amount
    vestingEnd = block.timestamp;

    IStakedLyra stakedToken = factory.stakedToken();

    uint256 balance = _tokenBalance(token);
    uint256 stBalance = _stakedTokenBalance(stakedToken);
    uint256 amountToRemove = balance.add(stBalance).sub(vested);
    uint256 stAmountToRemove;

    if (stBalance > 0) {
      stAmountToRemove = stBalance > vested ? stBalance.sub(vested) : 0;
      amountToRemove = amountToRemove.sub(stAmountToRemove);
    }

    if (stAmountToRemove > 0) {
      _transferAsset(stakedToken, owner(), stAmountToRemove);
      emit Removed(address(stakedToken), stAmountToRemove);
    }

    if (amountToRemove > 0) {
      _transferAsset(token, owner(), amountToRemove);
      emit Removed(address(token), amountToRemove);
    }
  }

  /**
   * @dev Stakes tokens in the safety module, and start earning rewards. Receives the same amount of a
   * erc20 staked token representation.
   *
   * @param amount Amount to stake
   **/
  function smStake(uint256 amount) external onlyRecipient {
    IStakedLyra stakedToken = _getStakedToken();

    token.approve(address(stakedToken), amount);
    stakedToken.stake(address(this), amount);
  }

  /**
   * @dev Activates the stakedToken's cooldown period to unstake.
   *
   **/
  function smCooldown() external onlyRecipient {
    IStakedLyra stakedToken = _getStakedToken();
    stakedToken.cooldown();
  }

  /**
   * @dev Redeems staked tokens, and stop earning rewards. This must be called after the cooldown period.
   *
   * @param amount Amount to redeem
   **/
  function smRedeem(uint256 amount) external onlyRecipient {
    IStakedLyra stakedToken = _getStakedToken();
    stakedToken.redeem(address(this), amount);
  }

  /**
   * @dev Claims an `amount` of generated rewards by the staked Tokens
   * Unclaimed rewards will remain assigned to this contract after claiming vested tokens.
   *
   * @param to Address that will receive the rewards
   * @param amount Amount to claim. Use the max integer to claim all available rewards
   **/
  function smClaimRewards(address to, uint256 amount) external onlyRecipient {
    IStakedLyra stakedToken = _getStakedToken();
    stakedToken.claimRewards(to, amount);
  }

  /**
   * @dev Gets the amount available for claim
   *
   * @return the amount of vested tokens
   */
  function getClaimable() external view returns (uint256) {
    if (block.timestamp < vestingCliff) {
      return 0;
    }

    uint256 amount;
    if (block.timestamp >= vestingEnd) {
      amount = _totalBalance();
    } else {
      amount = _getClaimAmount();
    }

    return amount;
  }

  /**
   * @dev Transfers `amount` of `asset` to `to`
   *
   * @param asset Address of the token
   * @param to Address that will receive the assets
   * @param amount Amount of assets to transfer
   */
  function _transferAsset(
    IERC20 asset,
    address to,
    uint256 amount
  ) internal returns (bool) {
    return asset.transfer(to, amount);
  }

  /**
   * @dev Returns balance of `token` plus `stakedToken`
   * @return the total balance
   */
  function _totalBalance() internal view returns (uint256) {
    IStakedLyra stakedToken = factory.stakedToken();
    return _tokenBalance(token).add(_stakedTokenBalance(stakedToken));
  }

  /**
   * @dev Returns the `asset` balance of the escrow contract
   *
   * @param asset Address of the token
   * @return the balance amount
   */
  function _tokenBalance(IERC20 asset) internal view returns (uint256) {
    return asset.balanceOf(address(this));
  }

  /**
   * @dev Returns the `stakedToken` balance of the escrow contract
   *
   * @param stakedToken Address of the staked token
   * @return the balance amount
   */
  function _stakedTokenBalance(IERC20 stakedToken) internal view returns (uint256) {
    return address(stakedToken) != address(0) ? _tokenBalance(stakedToken) : 0;
  }

  /**
   * @dev Calculates the amount available for claim
   *
   * @return the amount of vested tokens
   */
  function _getClaimAmount() internal view returns (uint256) {
    return vestingAmount.mul(block.timestamp.sub(lastUpdate)).div(vestingEnd.sub(vestingBegin));
  }

  /**
   * @dev Gets the stakedToken address and validates it
   *
   * @return the stakedToken address
   */
  function _getStakedToken() internal view returns (IStakedLyra) {
    IStakedLyra stakedToken = factory.stakedToken();
    require(address(stakedToken) != address(0), "stakedToken is 0x0");

    return stakedToken;
  }
}
