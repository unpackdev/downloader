// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Strings.sol";
import "./StorageSlot.sol";
import "./IWeightedValidator.sol";
import "./HasProxyAdmin.sol";

contract RoninValidator is Initializable, IWeightedValidator, HasProxyAdmin {
  uint256 internal _num;
  uint256 internal _denom;
  uint256 internal _totalWeights;

  /// @dev Mapping from validator address => weight
  mapping(address => uint256) internal _validatorWeight;
  /// @dev Mapping from governor address => weight
  mapping(address => uint256) internal _governorWeight;
  /// @dev Validators array
  address[] internal _validators;
  /// @dev Governors array
  address[] internal _governors;

  uint256 public nonce;

  /**
   * @dev Initializes contract storage.
   */
  function initialize(
    WeightedValidator[] calldata _initValidators,
    uint256 _numerator,
    uint256 _denominator
  ) external virtual initializer {
    _addValidators(_initValidators);
    _setThreshold(_numerator, _denominator);
  }

  /**
   * @dev See {IWeightedValidator-getValidatorWeight}.
   */
  function getValidatorWeight(address _validator) external view virtual returns (uint256) {
    return _validatorWeight[_validator];
  }

  /**
   * @dev See {IWeightedValidator-getGovernorWeight}.
   */
  function getGovernorWeight(address _governor) external view virtual returns (uint256) {
    return _governorWeight[_governor];
  }

  /**
   * @dev See {IWeightedValidator-sumValidatorWeights}.
   */
  function sumValidatorWeights(address[] calldata _addrList) external view virtual returns (uint256 _weight) {
    for (uint256 _i; _i < _addrList.length; _i++) {
      _weight += _validatorWeight[_addrList[_i]];
    }
  }

  /**
   * @dev See {IWeightedValidator-sumGovernorWeights}.
   */
  function sumGovernorWeights(address[] calldata _addrList) external view virtual returns (uint256 _weight) {
    for (uint256 _i; _i < _addrList.length; _i++) {
      _weight += _governorWeight[_addrList[_i]];
    }
  }

  /**
   * @dev See {IWeightedValidator-getValidatorInfo}.
   */
  function getValidatorInfo() external view virtual returns (WeightedValidator[] memory _list) {
    _list = new WeightedValidator[](_validators.length);
    address _validator;
    for (uint256 _i; _i < _list.length; _i++) {
      _validator = _validators[_i];
      _list[_i].validator = _validator;
      _list[_i].governor = _governors[_i];
      _list[_i].weight = _validatorWeight[_validator];
    }
  }

  /**
   * @dev See {IWeightedValidator-getValidators}.
   */
  function getValidators() external view virtual returns (address[] memory) {
    return _validators;
  }

  /**
   * @dev See {IWeightedValidator-getGovernors}.
   */
  function getGovernors() external view virtual returns (address[] memory) {
    return _governors;
  }

  /**
   * @dev See {IWeightedValidator-validators}.
   */
  function validators(uint256 _index) external view virtual returns (WeightedValidator memory) {
    address _validator = _validators[_index];
    return WeightedValidator(_validator, _governors[_index], _validatorWeight[_validator]);
  }

  /**
   * @dev See {IWeightedValidator-totalWeights}.
   */
  function totalWeights() external view virtual returns (uint256) {
    return _totalWeights;
  }

  /**
   * @dev See {IWeightedValidator-totalValidators}.
   */
  function totalValidators() external view virtual returns (uint256) {
    return _validators.length;
  }

  /**
   * @dev See {IWeightedValidator-addValidators}.
   */
  function addValidators(WeightedValidator[] calldata _validatorList) external virtual onlyAdmin {
    return _addValidators(_validatorList);
  }

  /**
   * @dev See {IWeightedValidator-updateValidators}.
   */
  function updateValidators(WeightedValidator[] calldata _validatorList) external virtual onlyAdmin {
    for (uint256 _i; _i < _validatorList.length; _i++) {
      _updateValidator(_validatorList[_i]);
    }
    emit ValidatorsUpdated(nonce++, _validatorList);
  }

  /**
   * @dev See {IWeightedValidator-removeValidators}.
   */
  function removeValidators(address[] calldata _validatorList) external virtual onlyAdmin {
    for (uint256 _i; _i < _validatorList.length; _i++) {
      _removeValidator(_validatorList[_i]);
    }
    emit ValidatorsRemoved(nonce++, _validatorList);
  }

  /**
   * @dev See {IQuorum-getThreshold}.
   */
  function getThreshold() external view virtual returns (uint256, uint256) {
    return (_num, _denom);
  }

  /**
   * @dev See {IQuorum-checkThreshold}.
   */
  function checkThreshold(uint256 _voteWeight) external view virtual returns (bool) {
    return _voteWeight * _denom >= _num * _totalWeights;
  }

  /**
   * @dev See {IQuorum-minimumVoteWeight}.
   */
  function minimumVoteWeight() external view virtual returns (uint256) {
    return (_num * _totalWeights + _denom - 1) / _denom;
  }

  /**
   * @dev See {IQuorum-setThreshold}.
   */
  function setThreshold(uint256 _numerator, uint256 _denominator)
    external
    virtual
    onlyAdmin
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    return _setThreshold(_numerator, _denominator);
  }

  /**
   * @dev Sets threshold and return the old one.
   */
  function _setThreshold(uint256 _numerator, uint256 _denominator)
    internal
    virtual
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    require(_numerator <= _denominator, "RoninValidator: invalid threshold");
    _previousNum = _num;
    _previousDenom = _denom;
    _num = _numerator;
    _denom = _denominator;
    emit ThresholdUpdated(nonce++, _numerator, _denominator, _previousNum, _previousDenom);
  }

  /**
   * @dev Adds multiple validators.
   */
  function _addValidators(WeightedValidator[] calldata _validatorList) internal virtual {
    for (uint256 _i; _i < _validatorList.length; _i++) {
      _addValidator(_validatorList[_i]);
    }
    emit ValidatorsAdded(nonce++, _validatorList);
  }

  /**
   * @dev Adds the address list as validators.
   *
   * Requirements:
   * - The weight is larger than 0.
   * - The validator is not added.
   *
   */
  function _addValidator(WeightedValidator memory _v) internal virtual {
    require(_v.weight > 0, "RoninValidator: invalid weight");

    if (_validatorWeight[_v.validator] > 0) {
      revert(
        string(
          abi.encodePacked(
            "RoninValidator: ",
            Strings.toHexString(uint160(_v.validator), 20),
            " is a validator already"
          )
        )
      );
    }

    if (_governorWeight[_v.governor] > 0) {
      revert(
        string(
          abi.encodePacked("RoninValidator: ", Strings.toHexString(uint160(_v.validator), 20), " is a governor already")
        )
      );
    }

    _validators.push(_v.validator);
    _governors.push(_v.governor);
    _validatorWeight[_v.validator] = _v.weight;
    _governorWeight[_v.governor] = _v.weight;
    _totalWeights += _v.weight;
  }

  /**
   * @dev Removes the address list as validators.
   *
   * Requirements:
   * - The weight is larger than 0.
   * - The validator is added.
   *
   */
  function _updateValidator(WeightedValidator memory _v) internal virtual {
    require(_v.weight > 0, "RoninValidator: invalid weight");

    uint256 _weight = _validatorWeight[_v.validator];
    if (_weight == 0) {
      revert(
        string(
          abi.encodePacked("RoninValidator: ", Strings.toHexString(uint160(_v.validator), 20), " is not a validator")
        )
      );
    }

    uint256 _count = _validators.length;
    for (uint256 _i = 0; _i < _count; _i++) {
      if (_validators[_i] == _v.validator) {
        _totalWeights -= _weight;
        _totalWeights += _v.weight;

        if (_governors[_i] != _v.governor) {
          require(_governorWeight[_v.governor] == 0, "RoninValidator: query for duplicated governor");
          delete _governorWeight[_governors[_i]];
          _governors[_i] = _v.governor;
        }

        _validatorWeight[_v.validator] = _v.weight;
        _governorWeight[_v.governor] = _v.weight;
        return;
      }
    }
  }

  /**
   * @dev Removes the address list as validators.
   *
   * Requirements:
   * - The validator is added.
   *
   */
  function _removeValidator(address _addr) internal virtual {
    uint256 _weight = _validatorWeight[_addr];
    if (_weight == 0) {
      revert(
        string(abi.encodePacked("RoninValidator: ", Strings.toHexString(uint160(_addr), 20), " is not a validator"))
      );
    }

    uint256 _index;
    uint256 _count = _validators.length;
    for (uint256 _i = 0; _i < _count; _i++) {
      if (_validators[_i] == _addr) {
        _index = _i;
        break;
      }
    }

    _totalWeights -= _weight;
    delete _validatorWeight[_addr];
    _validators[_index] = _validators[_count - 1];
    _validators.pop();

    delete _governorWeight[_governors[_index]];
    _governors[_index] = _governors[_count - 1];
    _governors.pop();
  }
}
