// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";

import "./KibbleAccessControl.sol";
import "./ERC20.sol";

abstract contract KibbleBase is ERC20, KibbleAccessControl {
  using SafeMath for uint256;
  bytes32 public constant DELEGATE_BY_POWER_TYPEHASH =
    keccak256(
      'DelegateByPower(address delegatee,uint256 type,uint256 nonce,uint256 expiry)'
    );

  bytes32 public constant DELEGATE_TYPEHASH =
    keccak256('Delegate(address delegatee,uint256 nonce,uint256 expiry)');

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint128 blockNumber;
    uint256 votes;
  }

  /// @notice Enum of powers delegate can have
  enum DelegationPower {
    Proposition,
    Voting
  }

  /// @notice emitted when a user delegates to another
  /// @param _delegator the delegator
  /// @param _delegatee the delegatee
  /// @param _power power querying
  event DelegateChanged(
    address indexed _delegator,
    address indexed _delegatee,
    DelegationPower _power
  );

  /// @notice emitted when an action changes the delegated power of a user
  /// @param _user the user which delegated power has changed
  /// @param _amount the amount of delegated power for the user
  /// @param _power power querying
  event DelegatedPowerChanged(
    address indexed _user,
    uint256 _amount,
    DelegationPower _power
  );

  /// @notice grant single delegation power to delegatee
  /// @param _delegatee giving power to
  /// @param _power the power being given
  function delegateByPower(address _delegatee, DelegationPower _power)
    external
  {
    _delegateByPower(msg.sender, _delegatee, _power);
  }

  /// @notice grant delegation power to delegatee
  /// @param _delegatee giving power to
  function delegate(address _delegatee) external {
    _delegateByPower(msg.sender, _delegatee, DelegationPower.Proposition);
    _delegateByPower(msg.sender, _delegatee, DelegationPower.Voting);
  }

  /// @notice returns the delegatee of an user by power
  /// @param _delegator the address of the delegator
  /// @param _power power querying
  function getDelegateeByPower(address _delegator, DelegationPower _power)
    external
    view
    returns (address)
  {
    (
      ,
      ,
      mapping(address => address) storage delegates
    ) = _getDelegationDataByPower(_power);

    return _getDelegatee(_delegator, delegates);
  }

  /// @notice gets the current delegated power of a user. The current power is the
  /// power delegated at the time of the last checkpoint
  /// @param _user the user
  /// @param _power power querying
  function getPowerCurrent(address _user, DelegationPower _power)
    external
    view
    returns (uint256 currentPower_)
  {
    (
      mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints,
      mapping(address => uint256) storage checkpointsCounts,

    ) = _getDelegationDataByPower(_power);

    currentPower_ = _searchByBlockNumber(
      checkpoints,
      checkpointsCounts,
      _user,
      block.number
    );
  }

  /// @notice queries the delegated power of a user at a certain block
  /// @param _user the user
  /// @param _blockNumber the block number querying by
  /// @param _power the power querying by
  function getPowerAtBlock(
    address _user,
    uint256 _blockNumber,
    DelegationPower _power
  ) external view returns (uint256 powerAtBlock_) {
    (
      mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints,
      mapping(address => uint256) storage checkpointsCounts,

    ) = _getDelegationDataByPower(_power);

    powerAtBlock_ = _searchByBlockNumber(
      checkpoints,
      checkpointsCounts,
      _user,
      _blockNumber
    );
  }

  /// @notice delegates the specific power to a delegate
  /// @param _delegator the user which delegated power has changed
  /// @param _delegatee the user which delegated power has changed
  /// @param _power the power being given
  function _delegateByPower(
    address _delegator,
    address _delegatee,
    DelegationPower _power
  ) internal {
    require(
      _delegatee != address(0),
      'KibbleBase: _delegateByPower: invalid delegate'
    );

    (
      ,
      ,
      mapping(address => address) storage delegates
    ) = _getDelegationDataByPower(_power);

    uint256 delegatorBalance = balanceOf(_delegator);

    address previousDelegatee = _getDelegatee(_delegator, delegates);

    delegates[_delegator] = _delegatee;

    _moveDelegatesByPower(
      previousDelegatee,
      _delegatee,
      delegatorBalance,
      _power
    );
    emit DelegateChanged(_delegator, _delegatee, _power);
  }

  /// @notice reassigns delegation to another user
  /// @param _from the user from which delegated power is moved
  /// @param _to the user that will receive the delegated power
  /// @param _amount the amount of delegated power to be moved
  /// @param _power the power being reassigned
  function _moveDelegatesByPower(
    address _from,
    address _to,
    uint256 _amount,
    DelegationPower _power
  ) internal {
    if (_from == _to) {
      return;
    }

    (
      mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints,
      mapping(address => uint256) storage checkpointsCounts,

    ) = _getDelegationDataByPower(_power);

    if (_from != address(0)) {
      uint256 previous = 0;
      uint256 fromCheckpointsCount = checkpointsCounts[_from];

      if (fromCheckpointsCount != 0) {
        previous = checkpoints[_from][fromCheckpointsCount - 1].votes;
      } else {
        previous = balanceOf(_from);
      }
      uint256 newVal = previous.sub(_amount);

      _writeCheckpoint(checkpoints, checkpointsCounts, _from, uint128(newVal));

      emit DelegatedPowerChanged(_from, newVal, _power);
    }
    if (_to != address(0)) {
      uint256 previous = 0;
      uint256 toCheckpointsCount = checkpointsCounts[_to];
      if (toCheckpointsCount != 0) {
        previous = checkpoints[_to][toCheckpointsCount - 1].votes;
      } else {
        previous = balanceOf(_to);
      }

      uint256 newVal = previous.add(_amount);

      _writeCheckpoint(checkpoints, checkpointsCounts, _to, uint128(newVal));

      emit DelegatedPowerChanged(_to, newVal, _power);
    }
  }

  /// @notice searches a checkpoint by block number. Uses binary search.
  /// @param _checkpoints the checkpoints mapping
  /// @param _checkpointsCounts the number of checkpoints
  /// @param _user the user for which the checkpoint is being searched
  /// @param _blockNumber the block number being searched
  function _searchByBlockNumber(
    mapping(address => mapping(uint256 => Checkpoint)) storage _checkpoints,
    mapping(address => uint256) storage _checkpointsCounts,
    address _user,
    uint256 _blockNumber
  ) internal view returns (uint256 checkpoint_) {
    require(
      _blockNumber <= block.number,
      'KibbleBase: _searchByBlockNumber: invalid block number'
    );

    uint256 checkpointsCount = _checkpointsCounts[_user];

    if (checkpointsCount == 0) {
      return balanceOf(_user);
    }

    // First check most recent balance
    if (_checkpoints[_user][checkpointsCount - 1].blockNumber <= _blockNumber) {
      return _checkpoints[_user][checkpointsCount - 1].votes;
    }

    // Next check implicit zero balance
    if (_checkpoints[_user][0].blockNumber > _blockNumber) {
      return 0;
    }

    uint256 lower = 0;
    uint256 upper = checkpointsCount - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory checkpoint = _checkpoints[_user][center];
      if (checkpoint.blockNumber == _blockNumber) {
        return checkpoint.votes;
      } else if (checkpoint.blockNumber < _blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }

    checkpoint_ = _checkpoints[_user][lower].votes;
  }

  /// @notice get delegation data by power
  /// @param _power the power querying by from
  function _getDelegationDataByPower(DelegationPower _power)
    internal
    view
    virtual
    returns (
      mapping(address => mapping(uint256 => Checkpoint)) storage, //checkpoint
      mapping(address => uint256) storage, //checkpoints count
      mapping(address => address) storage //delegatees list
    );

  /// @notice Writes a checkpoint for an owner of tokens
  /// @param _checkpoints the checkpoints mapping
  /// @param _checkpointsCounts the number of checkpoints
  /// @param _owner The owner of the tokens
  /// @param _value The value after the operation
  function _writeCheckpoint(
    mapping(address => mapping(uint256 => Checkpoint)) storage _checkpoints,
    mapping(address => uint256) storage _checkpointsCounts,
    address _owner,
    uint128 _value
  ) internal {
    uint128 currentBlock = uint128(block.number);

    uint256 ownerCheckpointsCount = _checkpointsCounts[_owner];
    mapping(uint256 => Checkpoint) storage checkpointsOwner = _checkpoints[
      _owner
    ];

    // Doing multiple operations in the same block
    if (
      ownerCheckpointsCount != 0 &&
      checkpointsOwner[ownerCheckpointsCount - 1].blockNumber == currentBlock
    ) {
      checkpointsOwner[ownerCheckpointsCount - 1].votes = _value;
    } else {
      checkpointsOwner[ownerCheckpointsCount] = Checkpoint(
        currentBlock,
        _value
      );
      _checkpointsCounts[_owner] = ownerCheckpointsCount + 1;
    }
  }

  /// @notice returns the user delegatee. If a user never performed any delegation,
  /// his delegated address will be 0x0. In that case we simply return the user itself
  /// @param _delegator the address of the user for which return the delegatee
  /// @param _delegates the array of delegates for a particular type of delegation
  function _getDelegatee(
    address _delegator,
    mapping(address => address) storage _delegates
  ) internal view returns (address delegtee_) {
    address previousDelegatee = _delegates[_delegator];

    delegtee_ = previousDelegatee == address(0)
      ? _delegator
      : previousDelegatee;
  }
}
