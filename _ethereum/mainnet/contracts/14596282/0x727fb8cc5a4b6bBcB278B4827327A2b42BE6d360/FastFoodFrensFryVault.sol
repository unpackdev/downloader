// SPDX-License-Identifier: MIT

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@ FastFoodFrensFryVault @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@,,,,,,,@@@@@@@@@@***,,,@@@@@@@@@@,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@,,,,,,,@@@@@@@@@@***,,,@@@@@@@@@@,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@,,,,,,,***@@@****,,,,,,****@@@***,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@,,,,,,,***@@@****,,,,,,****@@@***,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@,,,,,,,,,,***,,,,,,,,,,,,,,***,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@(((((((((((((////(((((((((((((///(((((((@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@((((((####################((((################@@@@@@@@@@***(@@@@@@@@
// @@@@@@@@(((((((///((((##########@@@###////##########@@@###@@@@@@@@@***@#***(@@@@
// @@@@@@@@(((((((///((((##########@@@###////##########@@@###@@@@@@@****@**@**@&**/
// @@@@@///(((((((((((((((((#######@@@///(((((((#######@@@///@@@@@@***@**@@*/@***&@
// @@@@@((((((((((((((((((((#############(((((((#############@@@@@@*****@**@****@@@
// @@@@@(((((((///(((((((((((((((((((((((((((///(((((((((((((@@@@@@*******@***@@@@@
// @@@@@(((((((///(((((((((((((((((((((((((((///(((((((((((((@@@@@@@********/@@@@@@
// @@@@@(((((((((((((////////////////////////////////////////@@@@@@//@@@@@@@@@@@@@@
// @@@@@///((((((((((////&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@//@@@@@@@@@@@@@@@
// @@@@@@@@((((((((((((((////////////////////////////////////@@@//@@@@@@@@@@@@@@@@@
// @@@@@@@@((((((((((((((////////////////////////////////////@@//@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@(((///(((((((((((((((((///((((((((((((((@@@@**@//@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((@@@@@@@@@@/(((%@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@(((((((((((((///(((((((((((((((((((((((%@**(((@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@(((((((((((((///((((((((((((((((((((((@#*//(@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@///@@@((((((((((((((((((((////(((@@@@@**@//@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((@@@@@**/@@@@@@@@@@@@@@@@@@@@@@@@@@@

pragma solidity 0.8.11;

import "./MathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./Initializable.sol";

import "./IERC721.sol";
import "./IERC20Burnable.sol";

import "./BasicRNGUpgradeable.sol";

/**
 * @title Fast Food Frens' Fry Vault
 * @notice Deposit your Fast Food Frens and earn fries.
 */
contract FastFoodFrensFryVault is Initializable, OwnableUpgradeable, PausableUpgradeable, BasicRNGUpgradeable {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  event HardWorkerTaxed(address indexed account, uint256 amount);
  event HardWorkerPaid(address indexed account, uint256 amount);

  event TaxTheftSuccessful(address indexed account, uint256 indexed id, uint256 total, uint256 tax);
  event TaxTheftFail(address indexed account, uint256 indexed id, uint256 total, uint256 tax);

  /* -------------------------------------------------------------------------- */
  /*                                Farming State                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Rewards end timestamp.
  uint256 public endTime;

  /// @notice Rewards emitted per day staked.
  uint256 public rate;

  /// @notice Staking token contract address.
  IERC721 public stakingToken;

  /// @notice Rewards token contract address.
  IERC20Burnable public rewardToken;

  /// @notice Spookies token contract address.
  IERC721 public spookiesToken;

  /// @notice Fast Food Doges token contract address.
  IERC721 public dogesToken;

  /// @notice Set of staked token ids by address.
  mapping(address => EnumerableSetUpgradeable.UintSet) internal _depositedIds;

  /// @notice Mapping of timestamps from each staked token id.
  mapping(uint256 => uint256) internal _depositedTimestamps;

  /// @notice Mapping of timestamps of initial staking date from each staked token id.
  mapping(uint256 => uint256) internal _initialDepositedTimestamps;

  /* -------------------------------------------------------------------------- */
  /*                             Staking Variables                              */
  /* -------------------------------------------------------------------------- */

  /// @notice Price in FRY to unlock before minStakingPeriod
  uint128 public earlyWithdrawPenalty;

  /// @notice Min staking time
  uint64 public minStakingPeriod;

  /// @notice Hardworker are subject to  taxation
  uint32 public hardworkerTax;

  /// @notice Tax Thief fail subject to higher taxation
  uint32 public taxtheftTax;

  /* -------------------------------------------------------------------------- */
  /*                           initialize contract                             */
  /* -------------------------------------------------------------------------- */

  /// @notice Initialize contract
  function initialize(
    address newStakingToken,
    address newRewardToken,
    address newSpookiesToken,
    address newDogesToken,
    uint256 newRate,
    uint256 newEndTime,
    uint128 newEarlyWithdrawPenalty,
    uint64 newMinStakingPeriod,
    uint32 newHardworkerTax,
    uint32 newTaxtheftTax
  ) external initializer {
    __Ownable_init();
    __Pausable_init();

    stakingToken = IERC721(newStakingToken); // FFF
    rewardToken = IERC20Burnable(newRewardToken); // FRY
    spookiesToken = IERC721(newSpookiesToken); // Spookies
    dogesToken = IERC721(newDogesToken); // FFD
    rate = newRate; // Daily emissions by token
    endTime = newEndTime; // End date timemstamp

    earlyWithdrawPenalty = newEarlyWithdrawPenalty; //169 ether
    minStakingPeriod = newMinStakingPeriod; //90 days
    hardworkerTax = newHardworkerTax; // 69
    taxtheftTax = newTaxtheftTax; //169

    // approve contract for rewardToken
    rewardToken.approve(address(this), type(uint256).max);

    _pause();
  }

  /* -------------------------------------------------------------------------- */
  /*                         Deposit / Withdraw                                 */
  /* -------------------------------------------------------------------------- */

  /// @notice Deposit tokens with `ids`. Tokens MUST have been approved to this contract first.
  function deposit(uint256[] memory ids) external whenNotPaused {
    for (uint256 i; i < ids.length; i++) {
      // Add the new deposit to the mapping
      _depositedIds[msg.sender].add(ids[i]);
      _initialDepositedTimestamps[ids[i]] = block.timestamp;
      _depositedTimestamps[ids[i]] = block.timestamp;

      // Transfer the deposited token to this contract
      stakingToken.transferFrom(msg.sender, address(this), ids[i]);
    }
  }

  /// @notice Withdraw tokens with `ids` and claim their pending rewards.
  function withdraw(uint256[] memory ids) external whenNotPaused {
    uint256 penalty = getEarlyWithdrawPenalty(ids);
    if (penalty > 0) rewardToken.burnFrom(msg.sender, penalty);

    uint256 collectionBonus = getCollectionsBonus(msg.sender);
    uint256 totalRewards;

    for (uint256 i; i < ids.length; i++) {
      require(_depositedIds[msg.sender].contains(ids[i]), "Query for a token you don't own");
      uint256 timeBonus = getTimeBonus(ids[i]);

      totalRewards += (_rewards(_depositedTimestamps[ids[i]]) * (1000 + collectionBonus + timeBonus)) / 1000;
      _depositedIds[msg.sender].remove(ids[i]);
      delete _initialDepositedTimestamps[ids[i]];
      delete _depositedTimestamps[ids[i]];

      stakingToken.safeTransferFrom(address(this), msg.sender, ids[i]);
    }

    payHardworker(totalRewards);
  }

  /// @notice Calculate total rewards for given account without tax
  /// @param account Holder address.
  function earned(address account) external view returns (uint256[] memory rewards) {
    uint256 length = _depositedIds[account].length();
    uint256 collectionBonus = getCollectionsBonus(account);

    rewards = new uint256[](length);

    for (uint256 i; i < length; i++) {
      uint256 tokenId = _depositedIds[account].at(i);
      uint256 timeBonus = getTimeBonus(tokenId);

      rewards[i] = (_rewards(_depositedTimestamps[tokenId]) * (1000 + collectionBonus + timeBonus)) / 1000;
    }
  }

  /// @notice Internally calculates base rewards for token `_id`.
  function _rewards(uint256 timestamp) internal view returns (uint256) {
    if (timestamp == 0) return 0;
    return ((MathUpgradeable.min(block.timestamp, endTime) - timestamp) * rate) / 1 days;
  }

  /// @notice Retrieve token initialDepositedTimestamps by account.
  /// @param account Token owner address.
  function initialDepositTimestampsOf(address account)
    external
    view
    returns (uint256[] memory initialDepositTimestamps)
  {
    uint256 length = _depositedIds[account].length();
    initialDepositTimestamps = new uint256[](length);
    for (uint256 i; i < length; i++)
      initialDepositTimestamps[i] = _initialDepositedTimestamps[_depositedIds[account].at(i)];
  }

  /// @notice Retrieve token ids deposited by account.
  /// @param account Token owner address.
  function depositsOf(address account) external view returns (uint256[] memory ids) {
    uint256 length = _depositedIds[account].length();
    ids = new uint256[](length);
    for (uint256 i; i < length; i++) ids[i] = _depositedIds[account].at(i);
  }

  /// @notice Claim all pending rewards with hardworkerTax
  function claimAll() external whenNotPaused {
    uint256 totalRewards = 0;
    uint256 collectionBonus = getCollectionsBonus(msg.sender);

    for (uint256 i; i < _depositedIds[msg.sender].length(); i++) {
      //Sum up rewards and update last checkpoint
      uint256 tokenId = _depositedIds[msg.sender].at(i);
      uint256 timestamp = _depositedTimestamps[tokenId];
      uint256 timeBonus = getTimeBonus(tokenId);

      _depositedTimestamps[tokenId] = block.timestamp;
      totalRewards += (_rewards(timestamp) * (1000 + collectionBonus + timeBonus)) / 1000;
    }

    payHardworker(totalRewards);
  }

  /* -------------------------------------------------------------------------- */
  /*                                Claim Logic                                 */
  /* -------------------------------------------------------------------------- */

  /// @notice Claim pending rewards for ids with hardworkerTax
  function claimHardWorker(uint256[] memory ids) external whenNotPaused {
    uint256 totalRewards = 0;
    uint256 collectionBonus = getCollectionsBonus(msg.sender);

    for (uint256 i; i < ids.length; i++) {
      require(_depositedIds[msg.sender].contains(ids[i]), "Query for a token you don't own");
      uint256 timestamp = _depositedTimestamps[ids[i]];
      uint256 timeBonus = getTimeBonus(ids[i]);

      _depositedTimestamps[ids[i]] = block.timestamp;
      totalRewards += (_rewards(timestamp) * (1000 + collectionBonus + timeBonus)) / 1000;
    }
    payHardworker(totalRewards);
  }

  /// @notice Claim pending rewards for ids trying to avoid tax
  function claimTaxTheft(uint256[] memory ids) external whenNotPaused {
    uint256 totalRewards = 0;
    uint256 collectionBonus = getCollectionsBonus(msg.sender);
    bool[] memory res = randomBoolArray(ids.length);

    for (uint256 i; i < ids.length; i++) {
      require(_depositedIds[msg.sender].contains(ids[i]), "Query for a token you don't own");
      uint256 timestamp = _depositedTimestamps[ids[i]];
      uint256 timeBonus = getTimeBonus(ids[i]);

      _depositedTimestamps[ids[i]] = block.timestamp;
      uint256 rewards = (_rewards(timestamp) * (1000 + collectionBonus + timeBonus)) / 1000;

      if (res[i]) {
        // TaxTheftSuccessful : no tax + bonus hardworkerTax
        uint256 bonux = (rewards * hardworkerTax) / 1000;
        uint256 total = rewards + bonux;
        totalRewards += total;
        emit TaxTheftSuccessful(msg.sender, ids[i], total, bonux);
      } else {
        //TaxTheftFail : tax is increased !
        uint256 malux = (rewards * taxtheftTax) / 1000;
        uint256 total = rewards - malux;
        totalRewards += total;
        emit TaxTheftFail(msg.sender, ids[i], total, malux);
      }
    }

    rewardToken.transfer(msg.sender, totalRewards); //send rewards
  }

  function payHardworker(uint256 totalRewards) internal {
    uint256 taxed = (totalRewards * hardworkerTax) / 1000;
    uint256 pay = totalRewards - taxed;

    rewardToken.burnFrom(address(this), taxed); //burn taxed
    rewardToken.transfer(msg.sender, pay); //send rewards

    emit HardWorkerTaxed(msg.sender, taxed);
    emit HardWorkerPaid(msg.sender, pay);
  }

  /* -------------------------------------------------------------------------- */
  /*                                Bonus Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Calculate time bonus for a stakingToken.
  function getTimeBonus(uint256 id) public view returns (uint256) {
    if (_initialDepositedTimestamps[id] == 0) return 0;
    uint256 stakingDuration = block.timestamp - _initialDepositedTimestamps[id];
    if (stakingDuration > 270 days) return 300;
    if (stakingDuration > 180 days) return 200;
    if (stakingDuration > 90 days) return 100;
    return 0;
  }

  /// @notice Calculate Collections Bonus for given account.
  function getCollectionsBonus(address account) public view returns (uint256) {
    uint256 spookiesBalance = spookiesToken.balanceOf(account);
    uint256 dogesBalance = dogesToken.balanceOf(account);

    return getSpookiesBonus(spookiesBalance) + getDogesBonus(dogesBalance);
  }

  /// @notice Calculate Spookies Bonus for given account.
  function getSpookiesBonus(uint256 balance) public pure returns (uint256) {
    if (balance > 15) return 69;
    if (balance > 8) return 50;
    if (balance > 6) return 40;
    if (balance > 4) return 30;
    if (balance > 2) return 20;
    if (balance > 0) return 10;
    return 0;
  }

  /// @notice Calculate Doges Bonus for given account.
  function getDogesBonus(uint256 balance) public pure returns (uint256) {
    if (balance > 19) return 69;
    if (balance > 12) return 50;
    if (balance > 9) return 40;
    if (balance > 6) return 30;
    if (balance > 3) return 20;
    if (balance > 0) return 10;
    return 0;
  }

  /* -------------------------------------------------------------------------- */
  /*                      Early Withdraw Penality                              */
  /* -------------------------------------------------------------------------- */

  /// @notice Withdraw tokens with `ids` and claim their pending rewards.
  function getEarlyWithdrawPenalty(uint256[] memory ids) public view returns (uint256) {
    uint256 totalPenality;
    for (uint256 i; i < ids.length; i++) {
      uint256 stakingDuration = block.timestamp - _initialDepositedTimestamps[ids[i]];
      if (stakingDuration < minStakingPeriod) totalPenality += earlyWithdrawPenalty;
    }
    return totalPenality;
  }

  /* -------------------------------------------------------------------------- */
  /*                   Staking Variables Setters                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set the new earlyWithdrawPenalty
  /// @param newEarlyWithdrawPenalty In FRY
  function setEarlyWithdrawPenalty(uint128 newEarlyWithdrawPenalty) external onlyOwner {
    earlyWithdrawPenalty = newEarlyWithdrawPenalty;
  }

  /// @notice Set the new minStakingPeriod
  /// @param newMinStakingPeriod In seconds
  function setMinStakingPeriod(uint64 newMinStakingPeriod) external onlyOwner {
    minStakingPeriod = newMinStakingPeriod;
  }

  /// @notice Set the new hardworkerTax
  /// @param newHardworkerTax (ex: 69 --> 6.9%)
  function setHardworkerTax(uint32 newHardworkerTax) external onlyOwner {
    hardworkerTax = newHardworkerTax;
  }

  /// @notice Set the new taxtheftTax
  /// @param newTaxtheftTax (ex: 169 --> 16.9%)
  function setTaxtheftTax(uint32 newTaxtheftTax) external onlyOwner {
    taxtheftTax = newTaxtheftTax;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set the new token rewards rate.
  /// @param newRate Emission rate in wei.
  function setRate(uint256 newRate) external onlyOwner {
    rate = newRate;
  }

  /// @notice Set the new rewards end time.
  /// @param newEndTime End timestamp.
  function setEndTime(uint256 newEndTime) external onlyOwner {
    require(newEndTime > block.timestamp, "End time must be greater than now");
    endTime = newEndTime;
  }

  /// @notice Set the new staking token contract address.
  /// @param newStakingToken Staking token address.
  function setStakingToken(address newStakingToken) external onlyOwner {
    stakingToken = IERC721(newStakingToken);
  }

  /// @notice Set the new reward token contract address.
  /// @param newRewardToken Rewards token address.
  function setRewardToken(address newRewardToken) external onlyOwner {
    rewardToken = IERC20Burnable(newRewardToken);
  }

  /// @notice Set the new spookies token contract address.
  /// @param newSpookiesToken Staking token address.
  function setSpookiesToken(address newSpookiesToken) external onlyOwner {
    spookiesToken = IERC721(newSpookiesToken);
  }

  /// @notice Set the new FFD token contract address.
  /// @param newDogesToken Staking token address.
  function setDogesToken(address newDogesToken) external onlyOwner {
    spookiesToken = IERC721(newDogesToken);
  }

  /// @notice Withdraw rewardToken in contract
  function withdrawRewardToken() external onlyOwner {
    uint256 balance = rewardToken.balanceOf(address(this));
    rewardToken.transferFrom(address(this), msg.sender, balance);
  }

  /// @notice Toggle if the contract is paused.
  function togglePaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }
}
