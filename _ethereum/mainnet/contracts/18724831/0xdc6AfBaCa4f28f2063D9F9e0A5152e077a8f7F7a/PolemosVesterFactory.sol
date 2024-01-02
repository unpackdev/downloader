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

import "./Ownable2Step.sol";
import "./EnumerableSet.sol";
import "./Clones.sol";
import "./PolemosVester.sol";
import "./IPolemos.sol";
import "./SafeERC20.sol";

contract PolemosVesterFactory is Ownable2Step {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  event VestingCreated(address recipient, address polemosVester, uint256 amount, uint16 vestingDuration);

  // Address of master contract which will be cloned
  address public masterVester;

  address public timelock;
  address public immutable polemos;
  mapping(address => PolemosVester[]) public polemosVestersByRecipient;
  EnumerableSet.AddressSet private _allRecipients;

  uint256 internal constant MULTIPLIER = 1e12;
  mapping(address => uint256) public vestingAmountByRecipient;
  mapping(address => uint256) public rewardDebtByRecipient;
  uint256 public totalVestingAmount;
  uint256 private accRewardAmountPerToken;

  constructor(address polemos_, address timelock_) {
    require(polemos_ != address(0) && timelock_ != address(0), 'PolemosVesterFactory:INVALID_ADDRESS');
    polemos = polemos_;
    timelock = timelock_;
  }

  function newPolemosVester(
    address recipient,
    uint256 vestingAmount,
    uint16 vestingDurationInDays,
    uint16 vestingStartDelayInDays,
    bool reverseVesting,
    bool interruptible
  ) public onlyOwner {
    if (masterVester == address(0)) {
      masterVester = address(new PolemosVester());
    }
    PolemosVester polemosVester = PolemosVester(Clones.clone(address(masterVester)));
    polemosVester.initialize(
      polemos,
      timelock,
      vestingAmount,
      vestingDurationInDays,
      vestingStartDelayInDays,
      reverseVesting,
      interruptible,
      recipient,
      address(this)
    );

    IERC20(polemos).safeTransferFrom(timelock, address(polemosVester), vestingAmount);

    polemosVestersByRecipient[recipient].push(polemosVester);
    _allRecipients.add(recipient);
    vestingAmountByRecipient[recipient] += vestingAmount;
    rewardDebtByRecipient[recipient] += (accRewardAmountPerToken * vestingAmount) / MULTIPLIER;
    totalVestingAmount += vestingAmount;

    emit VestingCreated(recipient, address(polemosVester), vestingAmount, vestingDurationInDays);
  }

  function claimReward() external {
    uint256 vestingAmount = vestingAmountByRecipient[msg.sender];
    if (vestingAmount == 0) {
      return;
    }
    uint256 rewardAmount = (accRewardAmountPerToken * vestingAmount) / MULTIPLIER;
    rewardAmount = rewardAmount - rewardDebtByRecipient[msg.sender];
    if (rewardAmount == 0) {
      return;
    }
    rewardDebtByRecipient[msg.sender] += rewardAmount;
    IERC20(polemos).safeTransfer(msg.sender, rewardAmount);
  }

  function addReward(uint256 amount) external {
    IERC20(polemos).safeTransferFrom(msg.sender, address(this), amount);
    accRewardAmountPerToken = accRewardAmountPerToken + (amount * MULTIPLIER) / totalVestingAmount;
  }

  function newNonInterruptibleVestingAgreement(
    address recipient,
    uint256 vestingAmount,
    uint16 vestingDurationInDays,
    uint16 vestingStartDelayInDays,
    bool reverseVesting
  ) external {
    newPolemosVester(recipient, vestingAmount, vestingDurationInDays, vestingStartDelayInDays, reverseVesting, false);
  }

  function newInterruptibleVestingAgreement(
    address recipient,
    uint256 vestingAmount,
    uint16 vestingDurationInDays,
    uint16 vestingStartDelayInDays,
    bool reverseVesting
  ) external {
    newPolemosVester(recipient, vestingAmount, vestingDurationInDays, vestingStartDelayInDays, reverseVesting, true);
  }

  function newSalaryAgreement(
    address recipient,
    uint256 vestingAmount,
    uint16 vestingDurationInDays,
    uint16 vestingStartDelayInDays
  ) external {
    newPolemosVester(recipient, vestingAmount, vestingDurationInDays, vestingStartDelayInDays, false, true);
  }

  function getAllRecipients() external view returns (address[] memory recipients) {
    uint256 length = _allRecipients.length();
    recipients = new address[](length);
    for (uint256 i = 0; i < length; ++i) {
      recipients[i] = _allRecipients.at(i);
    }
    return recipients;
  }

  function getPolemosVestersByRecipient(address recipient) external view returns (PolemosVester[] memory) {
    return polemosVestersByRecipient[recipient];
  }

  function setTimelock(address newTimelock) external onlyOwner {
    require(newTimelock != address(0), 'PolemosVesterFactory:INVALID_ADDRESS');
    timelock = newTimelock;
    transferOwnership(newTimelock);
  }
}
