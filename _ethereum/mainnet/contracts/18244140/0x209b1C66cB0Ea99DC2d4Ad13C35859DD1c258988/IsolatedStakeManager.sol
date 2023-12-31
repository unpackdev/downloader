// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable2Step.sol";
import "./IUnderlyingStakeable.sol";
import "./AuthorizationManager.sol";
import "./GoodAccounting.sol";

contract IsolatedStakeManager is Ownable2Step, AuthorizationManager, GoodAccounting {
  using SafeERC20 for IERC20;
  constructor(address account) AuthorizationManager(31) {
    /*
     * by index:
     * 0: can start stakes
     * 1: can end stakes
     * 2: can early end stakes
     * 3: can transfer balance to owner
     * 4: can transfer from owner
     */
    _setAddressAuthorization({
      account: account,
      settings: MAX_AUTHORIZATION
    });
    _transferOwnership(account);
  }
  /**
   * set authorization flags for a provided target
   * @param account the address to change settings for
   * @param settings the encoded setting (binary) to apply to the target address
   */
  function setAuthorization(address account, uint256 settings) external onlyOwner {
    _setAddressAuthorization({
      account: account,
      settings: settings
    });
  }
  /**
   * allow addresses to start stakes from tokens already in the contract
   * @param runner the anticipated address(es) that will be running the following method
   * @param stakeDays the number of days that can be passed for the address (to constrain griefing)
   * @param settings the settings to provide (only index 0 is relevant)
   */
  function setStartAuthorization(address runner, uint16 stakeDays, uint256 settings) external onlyOwner {
    _setAuthorization({
      key: _startAuthorizationKey({
        runner: runner,
        stakeDays: stakeDays
      }),
      settings: settings
    });
  }
  /**
   * gets the start authorization key given a runner and stake days
   * @param runner the anticipated address(es) that will be running the following method
   * @param stakeDays the number of days that can be passed for the address (to constrain griefing)
   */
  function startAuthorizationKey(address runner, uint256 stakeDays) external pure returns(bytes32) {
    return _startAuthorizationKey({
      runner: runner,
      stakeDays: stakeDays
    });
  }
  /**
   * stake a given amount of tokens for a given number of days
   * @param newStakedHearts the number of hearts to stake
   * @param newStakedDays the number of days to stake said hearts
   * @notice if 0 is provided then the balance of the contract will be utilized
   * this should generally only be used if tokens are sent to the contract
   * and end stakes are not occuring for a number of days
   * @notice if you do not have global start abilities, but do have scoped abilities
   * it is not rational to pass anything but zero for this method
   */
  function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external override {
    uint256 settings = _getAddressSettings({
      account: msg.sender
    });
    // blanket start authorization
    if (!_isOneAtIndex({
      settings: settings,
      index: ZERO
    })) {
      revert NotAllowed();
    }
    if (newStakedHearts > ZERO) {
      _transferFromOwner({
        amount: newStakedHearts
      });
    }
    _stakeStart({
      newStakedDays: newStakedDays
    });
  }
  /**
   * start a stakes, so long as sender has the authorization to do so from owner
   * @param newStakedDays the number of days to start a stake
   */
  function stakeStartWithAuthorization(uint256 newStakedDays) external {
    // scoped authorization - to keep non-permitted contracts from griefing users
    if (!_isOneAtIndex({
      settings: authorization[_startAuthorizationKey(msg.sender, newStakedDays)],
      index: ZERO
    })) {
      revert NotAllowed();
    }
    _stakeStart({
      newStakedDays: newStakedDays
    });
  }
  /**
   * transfer a number of hearts from the owner into the contract
   * @param newStakedHearts number of hearts to deposit into contract
   * @notice authorization occurs inside of the internal method
   */
  function transferFromOwner(uint256 newStakedHearts) external {
    _transferFromOwner(newStakedHearts);
  }
  /**
   * ends the stake on the underlying target contract (HEX)
   * and transfers tokens to the owner
   * @param stakeIndex the index of the stake in ownership list
   * @param stakeId the id held on the stake
   * @notice this method fails if the stake at the provided index does not match the stakeId
   */
  function stakeEnd(uint256 stakeIndex, uint40 stakeId) external override {
    StakeStore memory stake = _getStake({
      custodian: address(this),
      index: stakeIndex
    });
    if (!_settingsCheck({
      stake: stake
    })) {
      revert NotAllowed();
    }
    _endStake({
      stakeIndex: stakeIndex,
      stakeId: stakeId
    });
  }
  /**
   * transfers tokens to the owner of the contract
   */
  function transferToOwner() external payable {
    _transferToOwner();
  }
  /**
   * ends the stake on the underlying target contract (HEX)
   * and transfers tokens to the owner
   * @param stakeIndex the index of the stake in ownership list
   * @param stakeId the id held on the stake
   * @notice this method does not fail if the stake at the
   * provided index does not have the provided stake id
   * @notice this method does not fail if authorization
   * is not provided to the runner of this method
   * this is to give every opportunity for strangers (who are authorized)
   * to end stakes without risk of losing too much gas money
   */
  function checkAndStakeEnd(uint256 stakeIndex, uint40 stakeId) external {
    StakeStore memory stake = _getStake({
      custodian: address(this),
      index: stakeIndex
    });
    if (stake.stakeId != stakeId || !_settingsCheck({
      stake: stake
    })) {
      return;
    }
    _endStake({
      stakeIndex: stakeIndex,
      stakeId: stakeId
    });
  }
  /**
   * ends a stake on the underlying contract
   * @param stakeIndex stake index to end
   * @param stakeId stake id to end
   * @notice this will fail on the underlying if
   * the stakeIndex and stakeId does not match
   */
  function _endStake(uint256 stakeIndex, uint40 stakeId) internal {
    IUnderlyingStakeable(TARGET).stakeEnd(stakeIndex, stakeId);
  }
  /**
   * transfer balance to the owner of this contract
   */
  function _transferToOwner() internal {
    if (!_isOneAtIndex({
      settings: _getAddressSettings(msg.sender),
      index: THREE
    })) {
      revert NotAllowed();
    }
    IERC20(TARGET).safeTransfer(owner(), _balanceOf({
      owner: address(this)
    }));
  }
  /**
   * check the settings of the running address
   * @param stake the stake to check authorization over
   */
  function _settingsCheck(IUnderlyingStakeable.StakeStore memory stake) internal view returns(bool) {
    uint256 settings = _getAddressSettings(msg.sender);
    if (_isEarlyEnding(stake.lockedDay, stake.stakedDays, _currentDay())) {
      // can early end stake
      return _isOneAtIndex({
        settings: settings,
        index: TWO
      });
    } else {
      // can end stake
      return _isOneAtIndex({
        settings: settings,
        index: ONE
      });
    }
  }
  /**
   * get the start authorization key for an address and number of stake days
   * @param runner the address that will run the method
   * @param stakeDays the number of days to stake
   */
  function _startAuthorizationKey(address runner, uint256 stakeDays) internal pure returns(bytes32) {
    return bytes32(uint256(uint160(runner)) << SIXTEEN | uint16(stakeDays));
  }
  /**
   * starts a stake on the underlying contract for a given number of days
   * @param newStakedDays a number of days to start a stake for
   */
  function _stakeStart(uint256 newStakedDays) internal {
    uint256 stakedHearts = _balanceOf({
      owner: address(this)
    });
    if (stakedHearts > ZERO) {
      IUnderlyingStakeable(TARGET).stakeStart({
        newStakedHearts: stakedHearts,
        newStakedDays: newStakedDays
      });
    }
  }
  /**
   * transfer a number of hearts from the owner to this contract
   * @param amount number of hearts to transfer from owner
   */
  function _transferFromOwner(uint256 amount) internal {
    if (!_isOneAtIndex({
      settings: _getAddressSettings(msg.sender),
      index: FOUR
    })) {
      revert NotAllowed();
    }
    IERC20(TARGET).safeTransferFrom(owner(), address(this), amount);
  }
}
