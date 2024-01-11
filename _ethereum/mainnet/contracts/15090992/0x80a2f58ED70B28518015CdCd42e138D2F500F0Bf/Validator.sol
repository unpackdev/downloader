// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./SafeMath.sol";
// import "./Ownable.sol";
import "./Ownable.sol";

// contract IValidator {
//   event ValidatorAdded(uint256 indexed _id, address indexed _validator);
//   event ValidatorRemoved(uint256 indexed _id, address indexed _validator);
//   event ThresholdUpdated(
//     uint256 indexed _id,
//     uint256 indexed _numerator,
//     uint256 indexed _denominator,
//     uint256 _previousNumerator,
//     uint256 _previousDenominator
//   );

//   function isValidator(address _addr) public view returns (bool);
//   function getValidators() public view returns (address[] memory _validators);

//   function checkThreshold(uint256 _voteCount) public view returns (bool);
// }

// File: contracts/chain/common/Validator.sol

// contract Validator is IValidator {
contract Validator {
  using SafeMath for uint256;

  mapping(address => bool) validatorMap;
  address[] public validators;
  uint256 public validatorCount;

  uint256 public num;
  uint256 public denom;

  event ValidatorAdded(uint256 indexed _id, address indexed _validator);
  event ValidatorRemoved(uint256 indexed _id, address indexed _validator);
  event ThresholdUpdated(
    uint256 indexed _id,
    uint256 indexed _numerator,
    uint256 indexed _denominator,
    uint256 _previousNumerator,
    uint256 _previousDenominator
  );

  constructor(address[] memory _validators, uint256 _num, uint256 _denom)
    
  {
    validators = _validators;
    validatorCount = _validators.length;

    for (uint256 _i = 0; _i < validatorCount; _i++) {
      address _validator = _validators[_i];
      validatorMap[_validator] = true;
    }

    num = _num;
    denom = _denom;
  }

  function isValidator(address _addr)
    public
    view
    returns (bool)
  {
    return validatorMap[_addr];
  }

  function getValidators()
    public
    view
    returns (address[] memory _validators)
  {
    _validators = validators;
  }

  function checkThreshold(uint256 _voteCount)
    public
    view
    returns (bool)
  {
    return _voteCount.mul(denom) >= num.mul(validatorCount);
  }

  function _addValidator(uint256 _id, address _validator)
    internal
  {
    require(!validatorMap[_validator]);

    validators.push(_validator);
    validatorMap[_validator] = true;
    validatorCount++;

    emit ValidatorAdded(_id, _validator);
  }

  function _removeValidator(uint256 _id, address _validator)
    internal
  {
    require(isValidator(_validator));

    uint256 _index;
    for (uint256 _i = 0; _i < validatorCount; _i++) {
      if (validators[_i] == _validator) {
        _index = _i;
        break;
      }
    }

    validatorMap[_validator] = false;
    validators[_index] = validators[validatorCount - 1];
    validators.pop();

    validatorCount--;

    emit ValidatorRemoved(_id, _validator);
  }

  function _updateQuorum(uint256 _id, uint256 _numerator, uint256 _denominator)
    internal
  {
    require(_numerator <= _denominator);
    uint256 _previousNumerator = num;
    uint256 _previousDenominator = denom;

    num = _numerator;
    denom = _denominator;

    emit ThresholdUpdated(
      _id,
      _numerator,
      _denominator,
      _previousNumerator,
      _previousDenominator
    );
  }
}

// File: contracts/chain/mainchain/MainchainValidator.sol

/**
 * @title Validator
 * @dev Simple validator contract
 */
contract MainchainValidator is Validator, Ownable {
  uint256 nonce;

  constructor(
    address[] memory _validators,
    uint256 _num,
    uint256 _denom
  ) Validator(_validators, _num, _denom) {
  }

  function addValidators(address[] calldata _validators) external onlyOwner {
    for (uint256 _i; _i < _validators.length; ++_i) {
      _addValidator(nonce++, _validators[_i]);
    }
  }

  function removeValidator(address _validator) external onlyOwner {
    _removeValidator(nonce++, _validator);
  }

  function updateQuorum(uint256 _numerator, uint256 _denominator) external onlyOwner {
    _updateQuorum(nonce++, _numerator, _denominator);
  }
}
