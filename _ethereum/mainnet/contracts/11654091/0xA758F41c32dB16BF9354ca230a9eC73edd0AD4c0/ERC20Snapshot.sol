// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./Arrays.sol";
import "./Counters.sol";
import "./ERC20.sol";

abstract contract ERC20Snapshot is ERC20 {
  using SafeMath for uint256;
  using Arrays for uint256[];
  using Counters for Counters.Counter;

  struct Snapshots {
    uint256[] ids;
    uint256[] values;
  }

  mapping(address => Snapshots) private _accountBalanceSnapshots;
  Snapshots private _totalSupplySnapshots;

  Counters.Counter private _currentSnapshotId;

  event Snapshot(uint256 id);

  function _snapshot() internal virtual returns (uint256) {
    _currentSnapshotId.increment();

    uint256 currentId = _currentSnapshotId.current();
    emit Snapshot(currentId);
    return currentId;
  }

  function balanceOfAt(address account, uint256 snapshotId)
    public
    view
    returns (uint256)
  {
    (bool snapshotted, uint256 value) =
      _valueAt(snapshotId, _accountBalanceSnapshots[account]);

    return snapshotted ? value : balanceOf(account);
  }

  function totalSupplyAt(uint256 snapshotId) public view returns (uint256) {
    (bool snapshotted, uint256 value) =
      _valueAt(snapshotId, _totalSupplySnapshots);

    return snapshotted ? value : totalSupply();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    if (from == address(0)) {
      _updateAccountSnapshot(to);
      _updateTotalSupplySnapshot();
    } else if (to == address(0)) {
      _updateAccountSnapshot(from);
      _updateTotalSupplySnapshot();
    } else {
      _updateAccountSnapshot(from);
      _updateAccountSnapshot(to);
    }
  }

  function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
    private
    view
    returns (bool, uint256)
  {
    require(snapshotId > 0, 'ERC20Snapshot: id is 0');

    require(
      snapshotId <= _currentSnapshotId.current(),
      'ERC20Snapshot: nonexistent id'
    );

    uint256 index = snapshots.ids.findUpperBound(snapshotId);

    if (index == snapshots.ids.length) {
      return (false, 0);
    } else {
      return (true, snapshots.values[index]);
    }
  }

  function _updateAccountSnapshot(address account) private {
    _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
  }

  function _updateTotalSupplySnapshot() private {
    _updateSnapshot(_totalSupplySnapshots, totalSupply());
  }

  function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue)
    private
  {
    uint256 currentId = _currentSnapshotId.current();
    if (_lastSnapshotId(snapshots.ids) < currentId) {
      snapshots.ids.push(currentId);
      snapshots.values.push(currentValue);
    }
  }

  function _lastSnapshotId(uint256[] storage ids)
    private
    view
    returns (uint256)
  {
    if (ids.length == 0) {
      return 0;
    } else {
      return ids[ids.length - 1];
    }
  }
}
