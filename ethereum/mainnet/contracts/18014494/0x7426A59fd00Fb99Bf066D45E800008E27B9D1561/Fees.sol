// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFees.sol";
import "./Address.sol";
import "./Governable.sol";
import "./Pausable.sol";

contract Fees is IFees, Governable, Pausable {
  using Address for address payable;

  constructor(address payable treasuryFeeAddress_, address payable stakingFeeAddress_) Governable(_msgSender(), _msgSender()) {
    _treasuryFeeAddress = treasuryFeeAddress_;
    _stakingFeeAddress = stakingFeeAddress_;
    _exemptFromFees[_msgSender()] = true;

    // !!! setup some fee type presets

    // note this covers all staking contracts.
    _feeTypeAmountMap["DeployStaking"] = 5 * 10 ** 17; // 0.5eth
    // note nothing fancy - a standard token
    _feeTypeAmountMap["DeployStandardToken"] = 2 * 10 ** 17; // 0.2eth
    // note reflects tokens back to holders.
    _feeTypeAmountMap["DeployReflectionToken"] = 3 * 10 ** 17; // 0.3eth
    // note sells for eth OR token, distributes rewards to holders automatically.
    _feeTypeAmountMap["DeployDividendToken"] = 3 * 10 ** 17; // 0.3eth
    // note sells for eth, sends all eth to a "marketing wallet"
    _feeTypeAmountMap["DeployMarketingToken"] = 3 * 10 ** 17; // 0.3eth
    // note that CreateTokenLock fee only applies to regular tokens,
    // not LP tokens. LP tokens are always free.
    // this fee should allow you to deploy as many locks
    // for the project as needed.
    _feeTypeAmountMap["CreateTokenLock"] = 2 * 10 ** 17; // 0.2eth
  }

  address payable internal _treasuryFeeAddress;
  address payable internal _stakingFeeAddress;

  /** 0-10000 - 2 decimals of precision. all fees should add up to 10000 (100%) */
  uint16 internal _treasuryFee = 2000;
  uint16 internal _stakingFee = 8000;

  uint256 internal _treasuryFeesDistributed;
  uint256 internal _stakingFeesDistributed;

  mapping(address => bool) internal _exemptFromFees;
  mapping(string => uint256) internal _feeTypeAmountMap;

  /**
   * @return 0 if the msg sender is exempt from fees.
   * this may not be desired when checking current fee values.
   */
  function getFeeAmountForType(string memory feeType) external view override returns (uint256) {
    return _exemptFromFees[_msgSender()] ? 0 : _feeTypeAmountMap[feeType];
  }

  function setFeeAmountForType(string memory feeType, uint256 amount) external override onlyGovernor {
    _feeTypeAmountMap[feeType] = amount;
  }

  function setAddressExemptFromFees(address account, bool value) external override onlyOwner {
    _exemptFromFees[account] = value;
  }

  function isAddressExemptFromFees(address account) external view override returns (bool) {
    return _exemptFromFees[account];
  }

  function feesDistributed() external view override returns (uint256 total, uint256 treasury, uint256 staking) {
    treasury = _treasuryFeesDistributed;
    staking = _stakingFeesDistributed;
    total = _treasuryFeesDistributed + _stakingFeesDistributed;
  }

  function treasuryFeeAddress() external view override returns (address) {
    return _treasuryFeeAddress;
  }

  function setTreasuryFeeAddress(address payable value) external override onlyOwner {
    _treasuryFeeAddress = value;
  }

  function stakingFeeAddress() external view override returns (address) {
    return _stakingFeeAddress;
  }

  function setStakingFeeAddress(address payable value) external override onlyOwner {
    _stakingFeeAddress = value;
  }

  function getFees() external view override returns (uint16 treasury, uint16 staking) {
    treasury = _treasuryFee;
    staking = _stakingFee;
  }

  /** 0-10000 - 2 decimals of precision. all fees should add up to 10000 (100.00%) */
  function setFees(uint16 treasury, uint16 staking) external override onlyGovernor {
    require(treasury + staking == 10000, "Total fees must equal 10000");

    _treasuryFee = treasury;
    _stakingFee = staking;
  }

  function _distributeFees(uint256 amount) internal virtual {
    require(amount != 0, "Cannot distribute 0");

    // explicitly check for 0% fee to avoid any chance of
    // precision errors when one of the fees is disabled.
    uint256 treasuryAmount = _treasuryFee == 0 ? 0 : (amount * _treasuryFee / 10000);
    uint256 stakingAmount = _stakingFee == 0 ? 0 : (amount - treasuryAmount);

    if (treasuryAmount != 0) {
      _treasuryFeesDistributed += treasuryAmount;
      _treasuryFeeAddress.sendValue(treasuryAmount);
    }
    
    if (stakingAmount != 0) {
      _stakingFeesDistributed += stakingAmount;
      _stakingFeeAddress.sendValue(stakingAmount);
    }
  }

  /**
   * @dev allow incoming fees to be paused in case of emergency.
   * sending fees here while paused will result in a reverted tx.
   */
  receive() external payable virtual onlyNotPaused {
    _distributeFees(msg.value);
  }
}
