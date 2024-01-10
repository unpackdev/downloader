// SPDX-License-Identifier: MIT

/*

Coded with ♥ by

██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.4 <0.9.0;

import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Governable.sol";
import "./IVestingWallet.sol";

contract VestingWallet is IVestingWallet, Governable {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet internal _vestedTokens;
  EnumerableSet.AddressSet internal _beneficiaries;
  mapping(address => EnumerableSet.AddressSet) internal _tokensPerBeneficiary; // beneficiary => [tokens]
  /// @inheritdoc IVestingWallet
  mapping(address => uint256) public override totalAmountPerToken; // token => amount
  /// @inheritdoc IVestingWallet
  mapping(address => mapping(address => Benefit)) public override benefits; // token => beneficiary => benefit

  constructor(address _governance) Governable(_governance) {}

  // Views

  /// @inheritdoc IVestingWallet
  function releaseDate(address _token, address _beneficiary) external view override returns (uint256) {
    Benefit memory _benefit = benefits[_token][_beneficiary];

    return _benefit.startDate + _benefit.duration;
  }

  /// @inheritdoc IVestingWallet
  function releasableAmount(address _token, address _beneficiary) external view override returns (uint256) {
    Benefit memory _benefit = benefits[_token][_beneficiary];

    return _releasableSchedule(_benefit) - _benefit.released;
  }

  /// @inheritdoc IVestingWallet
  function getBeneficiaries() external view override returns (address[] memory) {
    return _beneficiaries.values();
  }

  /// @inheritdoc IVestingWallet
  function getTokens() external view override returns (address[] memory) {
    return _vestedTokens.values();
  }

  /// @inheritdoc IVestingWallet
  function getTokensOf(address _beneficiary) external view override returns (address[] memory) {
    return _tokensPerBeneficiary[_beneficiary].values();
  }

  // Methods

  /// @inheritdoc IVestingWallet
  function addBenefit(
    address _beneficiary,
    uint256 _startDate,
    uint256 _duration,
    address _token,
    uint256 _amount
  ) external override onlyGovernance {
    _addBenefit(_beneficiary, _startDate, _duration, _token, _amount);
    totalAmountPerToken[_token] += _amount;

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
  }

  /// @inheritdoc IVestingWallet
  function addBenefits(
    address _token,
    address[] calldata __beneficiaries,
    uint256[] calldata _amounts,
    uint256 _startDate,
    uint256 _duration
  ) external override onlyGovernance {
    uint256 _length = __beneficiaries.length;
    if (_length != _amounts.length) revert WrongLengthAmounts();

    uint256 _vestedAmount;

    for (uint256 _i; _i < _length; _i++) {
      _addBenefit(__beneficiaries[_i], _startDate, _duration, _token, _amounts[_i]);
      _vestedAmount += _amounts[_i];
    }

    totalAmountPerToken[_token] += _vestedAmount;

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _vestedAmount);
  }

  /// @inheritdoc IVestingWallet
  function removeBenefit(address _token, address _beneficiary) external override onlyGovernance {
    _removeBenefit(_token, _beneficiary);
  }

  /// @inheritdoc IVestingWallet
  function removeBeneficiary(address _beneficiary) external override onlyGovernance {
    while (_tokensPerBeneficiary[_beneficiary].length() > 0) {
      _removeBenefit(_tokensPerBeneficiary[_beneficiary].at(0), _beneficiary);
    }
  }

  /// @inheritdoc IVestingWallet
  function release(address _token) external override {
    _release(_token, msg.sender);
  }

  /// @inheritdoc IVestingWallet
  function release(address _token, address _beneficiary) external override {
    _release(_token, _beneficiary);
  }

  /// @inheritdoc IVestingWallet
  function release(address[] calldata _tokens) external override {
    _release(_tokens, msg.sender);
  }

  /// @inheritdoc IVestingWallet
  function release(address[] calldata _tokens, address _beneficiary) external override {
    _release(_tokens, _beneficiary);
  }

  /// @inheritdoc IVestingWallet
  function releaseAll() external override {
    _releaseAll(msg.sender);
  }

  /// @inheritdoc IVestingWallet
  function releaseAll(address _beneficiary) external override {
    _releaseAll(_beneficiary);
  }

  /// @inheritdoc IDustCollector
  function sendDust(address _token) external override onlyGovernance {
    uint256 _amount;

    _amount = IERC20(_token).balanceOf(address(this)) - totalAmountPerToken[_token];
    IERC20(_token).safeTransfer(governance, _amount);

    emit DustSent(_token, _amount, governance);
  }

  // Internal

  function _addBenefit(
    address _beneficiary,
    uint256 _startDate,
    uint256 _duration,
    address _token,
    uint256 _amount
  ) internal {
    if (_tokensPerBeneficiary[_beneficiary].contains(_token)) {
      _release(_token, _beneficiary);
    }

    _beneficiaries.add(_beneficiary);
    _vestedTokens.add(_token);
    _tokensPerBeneficiary[_beneficiary].add(_token);

    Benefit storage _benefit = benefits[_token][_beneficiary];
    _benefit.startDate = _startDate;
    _benefit.duration = _duration;

    uint256 pendingAmount = _benefit.amount - _benefit.released;
    _benefit.amount = _amount + pendingAmount;
    _benefit.released = 0;

    emit BenefitAdded(_token, _beneficiary, _benefit.amount, _startDate, _startDate + _duration);
  }

  function _release(address _token, address _beneficiary) internal {
    Benefit storage _benefit = benefits[_token][_beneficiary];

    uint256 _releasable = _releasableSchedule(_benefit) - _benefit.released;

    if (_releasable == 0) {
      return;
    }

    _benefit.released += _releasable;
    totalAmountPerToken[_token] -= _releasable;

    if (_benefit.released == _benefit.amount) {
      _deleteBenefit(_token, _beneficiary);
    }

    IERC20(_token).safeTransfer(_beneficiary, _releasable);

    emit BenefitReleased(_token, _beneficiary, _releasable);
  }

  function _release(address[] calldata _tokens, address _beneficiary) internal {
    uint256 _length = _tokens.length;
    for (uint256 _i; _i < _length; _i++) {
      _release(_tokens[_i], _beneficiary);
    }
  }

  function _releaseAll(address _beneficiary) internal {
    address[] memory _tokens = _tokensPerBeneficiary[_beneficiary].values();
    uint256 _length = _tokens.length;
    for (uint256 _i; _i < _length; _i++) {
      _release(_tokens[_i], _beneficiary);
    }
  }

  function _removeBenefit(address _token, address _beneficiary) internal {
    _release(_token, _beneficiary);

    Benefit storage _benefit = benefits[_token][_beneficiary];

    uint256 _transferToOwner = _benefit.amount - _benefit.released;

    totalAmountPerToken[_token] -= _transferToOwner;

    if (_transferToOwner != 0) {
      IERC20(_token).safeTransfer(msg.sender, _transferToOwner);
    }

    _deleteBenefit(_token, _beneficiary);

    emit BenefitRemoved(_token, _beneficiary, _transferToOwner);
  }

  function _releasableSchedule(Benefit memory _benefit) internal view returns (uint256) {
    uint256 _timestamp = block.timestamp;
    uint256 _start = _benefit.startDate;
    uint256 _duration = _benefit.duration;
    uint256 _totalAllocation = _benefit.amount;

    if (_timestamp <= _start) {
      return 0;
    } else {
      return Math.min(_totalAllocation, (_totalAllocation * (_timestamp - _start)) / _duration);
    }
  }

  function _deleteBenefit(address _token, address _beneficiary) internal {
    delete benefits[_token][_beneficiary];

    _tokensPerBeneficiary[_beneficiary].remove(_token);

    if (_tokensPerBeneficiary[_beneficiary].length() == 0) {
      _beneficiaries.remove(_beneficiary);
    }

    if (totalAmountPerToken[_token] == 0) {
      _vestedTokens.remove(_token);
    }
  }
}
