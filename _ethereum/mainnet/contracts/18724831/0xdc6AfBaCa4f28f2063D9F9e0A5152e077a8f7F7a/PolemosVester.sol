// SPDX-License-Identifier: MIT

/*
|   _____            _                                    |
|  |  __ \          | |                                   |
|  | |__) |   ___   | |   ___   _ __ ___     ___    ___   |
|  |  ___/   / _ \  | |  / _ \ | '_ ` _ \   / _ \  / __|  |
|  | |      | (_) | | | |  __/ | | | | | | | (_) | \__ \  |
|  |_|       \___/  |_|  \___| |_| |_| |_|  \___/  |___/  |
|                                                         |
|                                                         |
*/

pragma solidity ^0.8.0;
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IPolemos.sol";
import "./IPolemosVesterFactory.sol";

contract PolemosVester is OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event VestingInterrupted(address recipient, uint256 vestingBegin, uint256 vestingAmount);
  event NewTimelock(address timelock);

  uint256 public constant DAY = 1 days;
  uint256 public vestingBegin;
  uint256 public vestingEnd;
  uint256 public lastClaimTimestamp;
  uint256 public vestingAmount;
  uint16 public vestingStartDelayInDays;
  address public timelock;
  uint16 public vestingDurationInDays;
  bool public reverseVesting;
  bool public interruptible;
  address public polemos;
  address public factory;

  modifier onlyTimelock() {
    require(msg.sender == timelock, 'PolemosVester:ACCESS_DENIED');
    _;
  }

  function initialize(
    address polemos_,
    address timelock_,
    uint256 vestingAmount_,
    uint16 vestingDurationInDays_,
    uint16 vestingStartDelayInDays_,
    bool reverseVesting_,
    bool interruptible_,
    address recipient,
    address factory_
  ) external initializer {
    __Ownable_init();
    require(
      polemos_ != address(0) && timelock_ != address(0) && recipient != address(0),
      'PolemosVester:INVALID_ADDRESS'
    );
    require(vestingAmount_ > 0, 'PolemosVester:INVALID_AMOUNT');
    polemos = polemos_;
    vestingAmount = vestingAmount_;
    vestingDurationInDays = vestingDurationInDays_;
    reverseVesting = reverseVesting_;
    timelock = timelock_;
    vestingStartDelayInDays = vestingStartDelayInDays_;
    interruptible = interruptible_;
    transferOwnership(recipient);
    factory = factory_;
  }

  /**
   * @notice Activates contract
   */
  function activate() external onlyOwner {
    require(vestingBegin == 0, 'PolemosVester:ALREADY_ACTIVE');
    if (!reverseVesting) {
      IPolemos(polemos).delegate(owner());
    } else {
      IPolemos(polemos).delegate(timelock);
    }
    vestingBegin = lastClaimTimestamp = block.timestamp + (vestingStartDelayInDays * DAY);
    vestingEnd = vestingBegin + (vestingDurationInDays * DAY);
  }

  /**
   * @notice Calculates amount of tokens ready to be claimed
   * @return amount Tokens ready to be claimed
   */
  function claimable() public view returns (uint256 amount) {
    if (!active()) {
      amount = 0;
    } else if (block.timestamp >= vestingEnd) {
      amount = IPolemos(polemos).balanceOf(address(this));
    } else {
      // Claim linearly starting from when claimed lastly
      amount = (vestingAmount * (block.timestamp - lastClaimTimestamp)) / (vestingEnd - vestingBegin);
    }
  }

  /**
   * @notice Calculates amount of tokens still to be vested
   * @return amount Tokens still to be vested
   */
  function unvested() public view returns (uint256 amount) {
    uint256 balance = IPolemos(polemos).balanceOf(address(this));
    amount = active() ? balance - claimable() : balance;
  }

  /**
   * @notice Send claimable tokens to contract's owner
   */
  function claim() external {
    require(active() && vestingBegin <= block.timestamp, 'PolemosVester:NOT_STARTED');
    uint256 amount = claimable();
    lastClaimTimestamp = block.timestamp;
    IERC20Upgradeable(polemos).safeTransfer(owner(), amount);
  }

  /**
   * @notice Interrupts this vesting agreement and returns
   *         all unvested tokens to the address provided
   * @param collectionAccount Where to send unvested tokens
   */
  function interrupt(address collectionAccount) external onlyTimelock {
    require(interruptible || !active(), 'PolemosVester:CANNOT_INTERRUPT');
    require(collectionAccount != address(0), 'PolemosVester:INVALID_ADDRESS');
    IERC20Upgradeable(polemos).safeTransfer(collectionAccount, unvested());
    // if interrupted after activation we terminate vesting now
    if (vestingEnd != 0) {
      vestingEnd = block.timestamp;
    }
    emit VestingInterrupted(owner(), vestingBegin, vestingAmount);
  }

  /**
   * @notice Whether this contract has been activated
   * @return True if active
   */
  function active() public view returns (bool) {
    return vestingBegin != 0;
  }

  /**
   * @notice Replace timelock
   * @param newTimelock New timelock address
   */
  function setTimelock(address newTimelock) external onlyTimelock {
    require(newTimelock != address(0), 'PolemosVester:INVALID_ADDRESS');
    timelock = newTimelock;
    emit NewTimelock(newTimelock);
  }
}
