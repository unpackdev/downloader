// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IIdoStorage.sol";


/**
 * @title IdoStorage
 * @dev IdoStorage is a shared contract that stores IDO state,
 * allowing to manage rounds, referrals and KYC.
 */
contract IdoStorage is IIdoStorage, AccessControl, ReentrancyGuard {
  using SafeERC20 for IERC20;
  bytes32 public constant KYC_ROLE = keccak256('KYC_ROLE');
  bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
  bytes32 public constant CONTROLLER_ROLE = keccak256('CONTROLLER_ROLE');

  address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address internal constant DEFI = 0x0000000000000000000000000000000000000deF;

  uint256 internal constant MAX_INVESTMENT = 1000000000000000000000000;
  uint256 internal constant MIN_INVESTMENT = 1000000000000000000;

  uint256 public constant MAIN_REFERRAL_REWARD = 50;
  uint256 public constant SECONDARY_REFERRAL_REWARD = 50;

  State private _state;
  Round[] private _rounds;
  uint256 private _activeRound;
  
  uint256 private _kycCap;
  uint256 private _maxInvestment;
  uint256 private _minInvestment;
  mapping(address => bool) private _kyc;

  uint256 private _totalTokenSold;
  mapping(address => uint256) private _investments;
  mapping(address => mapping(uint256 => uint256)) private _balances;

  mapping(address => Referral) private _referrals;
  mapping(address => address) private _referralsBeneficiaries;
  mapping(address => mapping(address => uint256)) _referralsBalances;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(KYC_ROLE, _msgSender());
    _setupRole(OPERATOR_ROLE, _msgSender());
  }

  receive()
    external
    payable 
  {
    // solhint-disable-previous-line no-empty-blocks
  }

  function openIdo()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (_state != State.None) revert IdoStartedErr();

    _state = State.Opened;

    emit IdoStateUpdated(_state);
  }

  function closeIdo()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (!isOpened()) revert IdoClosedErr();

    _state = State.Closed;

    emit IdoStateUpdated(_state);
  }

  function setupRound(uint256 priceVestingShort_, uint256 priceVestingLong_, uint256 totalSupply_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (isClosed()) revert IdoClosedErr(); 

    _rounds.push(
      Round({
        defined: true,
        state: State.None,
        priceVestingShort: priceVestingShort_,
        priceVestingLong: priceVestingLong_,
        tokensSold: 0,
        totalSupply: totalSupply_
      })
    );

    emit RoundAdded(priceVestingShort_, priceVestingLong_, totalSupply_);
  }

  function setupReferrals(
    address[] calldata referrals_,
    uint256[] calldata mainRewards_,
    uint256[] calldata secondaryRewards_
  )
    external
    onlyRole(OPERATOR_ROLE)
  {
    if (isClosed()) revert IdoClosedErr(); 
    if (referrals_.length != mainRewards_.length || referrals_.length != secondaryRewards_.length) revert ArrayParamsInvalidLengthErr();

    uint256 length = referrals_.length;
    for (uint256 index = 0; index < length; index++) {
      _referrals[referrals_[index]] = Referral({
        defined: true,
        enabled: true,
        mainReward: mainRewards_[index],
        secondaryReward: secondaryRewards_[index]
      });

      emit ReferralSetup(referrals_[index], mainRewards_[index], secondaryRewards_[index]);
    }
  }

  function updateRoundPrice(uint256 index_, uint256 priceVestingShort_, uint256 priceVestingLong_) 
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (isClosed()) revert IdoClosedErr();
    if (!_rounds[index_].defined) revert RoundUndefinedErr(index_);
    if (_rounds[index_].state != State.None) revert RoundStartedErr(index_);

    _rounds[index_].priceVestingShort = priceVestingShort_;
    _rounds[index_].priceVestingLong = priceVestingLong_;

    emit RoundPriceUpdated(index_, priceVestingShort_, priceVestingLong_);
  }

  function updateRoundSupply(uint256 index_, uint256 totalSupply_) 
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (isClosed()) revert IdoClosedErr();
    if (!_rounds[index_].defined) revert RoundUndefinedErr(index_);
    if (_rounds[index_].state == State.Closed) revert RoundClosedErr(index_);
    if (_rounds[index_].tokensSold > totalSupply_) revert RoundInvalidSupplyErr(index_);

    _rounds[index_].totalSupply = totalSupply_;

    emit RoundSupplyUpdated(index_, totalSupply_);
  }

  function openRound(uint256 index_)
    external
    onlyRole(OPERATOR_ROLE)
  {
    if (!isOpened()) revert IdoClosedErr();
    if (!_rounds[index_].defined) revert RoundUndefinedErr(index_);
    if (_rounds[index_].state != State.None) revert RoundStartedErr(index_);

    if (_rounds[_activeRound].state == State.Opened) {
      _rounds[_activeRound].state = State.Closed;
    }
    _rounds[index_].state = State.Opened;
    _activeRound = index_;

    emit RoundOpened(index_);
  }

  function closeRound(uint256 index_)
    external
    onlyRole(OPERATOR_ROLE)
  {
    if (!_rounds[index_].defined) revert RoundUndefinedErr(index_);
    if (_rounds[index_].state != State.Opened) revert RoundClosedErr(index_);

    _rounds[index_].state = State.Closed;

    emit RoundClosed(index_);
  }

  function setKycPass(address beneficiary_, bool value_)
    external
    onlyRole(KYC_ROLE)
  {
    _kyc[beneficiary_] = value_;

    emit KycPassUpdated(beneficiary_, value_);
  }

  function setKycPassBatches(address[] calldata beneficiaries_, bool[] calldata values_)
    external
    onlyRole(KYC_ROLE)
  {
    if (beneficiaries_.length != values_.length) revert ArrayParamsInvalidLengthErr();

    uint256 length = beneficiaries_.length;
    for (uint256 index = 0; index < length; index++) {
      _kyc[beneficiaries_[index]] = values_[index];

      emit KycPassUpdated(beneficiaries_[index], values_[index]);
    }
  }

  function setMaxInvestment(uint256 investment_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (investment_ > MAX_INVESTMENT) revert MaxInvestmentErr(investment_, MAX_INVESTMENT);
    if (investment_ < _minInvestment) revert MinInvestmentErr(investment_, _minInvestment);

    _maxInvestment = investment_;

    emit MaxInvestmentUpdated(_maxInvestment);
  }

  function setMinInvestment(uint256 investment_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (investment_ < MIN_INVESTMENT) revert MinInvestmentErr(investment_, MIN_INVESTMENT);
    if (investment_ > _maxInvestment) revert MaxInvestmentErr(investment_, _maxInvestment);

    _minInvestment = investment_;

    emit MinInvestmentUpdated(_minInvestment);
  }

  function setKycCap(uint256 cap_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (_minInvestment > cap_ || cap_ > _maxInvestment) revert KycCaptRangeErr(cap_, _minInvestment, _maxInvestment);

    _kycCap = cap_;

    emit KycCapUpdated(cap_);
  }

  function setPurchaseState(
    address beneficiary_,
    address collateral_,
    uint256 investment_,
    uint256 tokensSold_,
    address referral_,
    uint256 mainReward_,
    uint256 tokenReward_
  )
    external
    onlyRole(CONTROLLER_ROLE)
  {
    _investments[beneficiary_] = _investments[beneficiary_] + investment_;
    _totalTokenSold = _totalTokenSold + tokensSold_;
    _rounds[_activeRound].tokensSold = _rounds[_activeRound].tokensSold + tokensSold_;
    _balances[beneficiary_][_activeRound] = _balances[beneficiary_][_activeRound] + tokensSold_;

    if (referral_ != address(0)) {
      if (!_referrals[referral_].defined) {
        _referrals[referral_].defined = true;
        _referrals[referral_].enabled = true;
        _referrals[referral_].mainReward = MAIN_REFERRAL_REWARD;
        _referrals[referral_].secondaryReward = SECONDARY_REFERRAL_REWARD;

        emit ReferralSetup(referral_, MAIN_REFERRAL_REWARD, SECONDARY_REFERRAL_REWARD);
      }
      _referralsBalances[referral_][collateral_] += mainReward_;
      _referralsBalances[referral_][DEFI] += tokenReward_;
      _referralsBeneficiaries[beneficiary_] = referral_;  
    }
  }

  function enableReferral(address referral_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (!_referrals[referral_].defined) revert ReferralUndefinedErr(referral_);
    if (_referrals[referral_].enabled) revert ReferralEnabledErr(referral_);
    
    _referrals[referral_].enabled = true;

    emit ReferralEnabled(referral_);
  }

  function disableReferral(address referral_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (!_referrals[referral_].defined) revert ReferralUndefinedErr(referral_);
    if (!_referrals[referral_].enabled) revert ReferralDisabledErr(referral_);

    _referrals[referral_].enabled = false;

    emit ReferralDisabled(referral_);
  }

  function claimRewards(address[] calldata collaterals_)
    external
    nonReentrant()
  {
    address referral_ = _msgSender();
    if (!_referrals[referral_].defined) revert ReferralUndefinedErr(referral_);
    if (!_referrals[referral_].enabled) revert ReferralDisabledErr(referral_);
    if (collaterals_.length == 0) revert CollateralsUndefinedErr();

    uint256 length = collaterals_.length;
    for (uint256 i = 0; i < length; i++) {
      address collateral = collaterals_[i];
      uint256 balance = _referralsBalances[referral_][collateral];
      if (balance == 0) {
        //No funds to transfer'
        continue;
      }

      _referralsBalances[referral_][collateral] = 0;
      if (collateral == ETH) {        
        (bool success, ) = referral_.call{value: balance}('');
        if (!success) revert NativeTransferErr();
      } else {
        IERC20(collateral).safeTransfer(referral_, balance);
      }

      emit ClaimedRewards(referral_, collateral, balance);
    }
  }

  function recoverNative()
    external 
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    uint256 balance = address(this).balance;

    (bool success, ) = _msgSender().call{value: balance}('');
    if (!success) revert NativeTransferErr();

    emit NativeRecovered(balance);
  }

  function recoverERC20(address token_, uint256 amount_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    IERC20(token_).safeTransfer(_msgSender(), amount_);

    emit ERC20Recovered(token_, amount_);
  }

  function getRoundsCount()
    external
    view
    returns (uint256)
  {
    return _rounds.length;
  }

  function getActiveRound()
    external
    view
    returns (uint256)
  {
    return _activeRound;
  }

  function getRound(uint256 index_)
    external
    view 
    returns (Round memory)
  {
    return _rounds[index_];
  }

  function getTotalTokenSold()
    external
    view
    returns (uint256)
  {
    return _totalTokenSold;
  }

  function balanceOf(uint256 round_, address beneficiary_)
    external
    view
    returns (uint256)
  {
    return _balances[beneficiary_][round_];
  }

  function rewardBalanceOf(address collateral_, address beneficiary_)
    external
    view
    returns (uint256)
  {
    return _referralsBalances[beneficiary_][collateral_];
  }

  function getMaxInvestment()
    external
    view
    returns (uint256)
  {
    return _maxInvestment;
  }

  function getMinInvestment()
    external
    view
    returns (uint256)
  {
    return _minInvestment;
  }

  function capOf(address beneficiary_)
    external
    view
    returns (uint256)
  {
    uint256 investment = _investments[beneficiary_];
    uint256 cap = _kycCap;
    if (hasKycPass(beneficiary_)) {
      cap = _maxInvestment;
    }
    if (investment > cap) {
      return 0;
    }
    return cap - investment;
  }

  function maxCapOf(address beneficiary_)
    external
    view
    returns (uint256)
  {
    uint256 investment = _investments[beneficiary_];
    if (investment > _maxInvestment) {
      return 0;
    }
    return _maxInvestment - investment;
  }

  function getKycCap()
    external
    view
    returns (uint256)
  {
    return _kycCap;
  }

  function getReferral(address beneficiary_, address referral_)
    external
    view
    returns (address)
  {
    Referral memory referral = _referrals[_referralsBeneficiaries[beneficiary_]];
    // Check if beneficiary already has assigned referral
    if (referral.defined && referral.enabled) {
      return _referralsBeneficiaries[beneficiary_];
    }

    referral = _referrals[referral_];
    // Check if proposed referral is a new one or enabled
    if (!referral.defined || referral.enabled) {
      return referral_;
    }

    return address(0);
  }

  function getReferralReward(address referral_)
    external
    view
    returns (uint256, uint256)
  {
    Referral memory referral = _referrals[referral_];
    if (referral.defined) {
      return (referral.mainReward, referral.secondaryReward);
    }
    return (MAIN_REFERRAL_REWARD, SECONDARY_REFERRAL_REWARD);
  }

  function isOpened()
    public
    view
    returns (bool)
  {
    return _state == State.Opened;
  }

  function isClosed()
    public
    view
    returns (bool)
  {
    return _state == State.Closed;
  }

  function getPrice(Vesting vesting_)
    public
    view
    returns (uint256)
  {
    if (_rounds[_activeRound].state == State.Opened) {
      if (vesting_ == Vesting.Short) {
        return _rounds[_activeRound].priceVestingShort;
      }
      return _rounds[_activeRound].priceVestingLong;
    }
    return 0;
  }

  function hasKycPass(address beneficiary_)
    public
    view
    returns (bool)
  {
    return _kyc[beneficiary_];
  }
}