// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract LifeDAO is ERC20, ERC20Burnable, Ownable, Pausable {
  using SafeMath for uint256;

  uint256 public initSupply = 10_000_000_000; // 10 billion

  struct LockInfo {
    uint256 amount;
    uint256 releaseTime;
  }

  mapping(address => LockInfo[]) private _lockedDetails;
  mapping(address => uint256) private _lockedBalances;

  event LockToken(address indexed account, uint256 amount, uint256 releasetime);
  event ReleaseToken(address indexed account, uint256 amount);

  /**
   * @dev Transfers and locks tokens.
   * @param to The address to transfer to.
   * @param value The value to be transferred.
   * @param lockdays The days of locking tokens.
   */
  function transferAndLock(
    address to,
    uint256 value,
    uint256 lockdays
  ) public whenNotPaused returns (bool) {
    require(to != address(0) && value != 0 && lockdays != 0);
    uint256 _releaseTime = block.timestamp.add(lockdays.mul(1 days));
    _lockedDetails[to].push(LockInfo({amount: value, releaseTime: _releaseTime}));
    _lockedBalances[to] = _lockedBalances[to].add(value);
    _transfer(msg.sender, address(this), value);
    emit LockToken(to, value, _releaseTime);
    return true;
  }

  /**
   * @dev unlock tokens.
   */
  function unlock(address account) public whenNotPaused {
    uint256 len = _lockedDetails[account].length;
    require(len != 0, "no locked");
    uint256 totalReleasable = 0;
    for (uint256 i = 0; i < len; i = i.add(1)) {
      LockInfo memory tmp = _lockedDetails[account][i];
      if (tmp.releaseTime != 0 && block.timestamp >= tmp.releaseTime) {
        totalReleasable = totalReleasable.add(tmp.amount);
        delete _lockedDetails[account][i];
      }
    }
    require(totalReleasable != 0, "non-releasable");
    _lockedBalances[account] = _lockedBalances[account].sub(totalReleasable);
    if (_lockedBalances[account] == 0) delete _lockedDetails[account];
    _transfer(address(this), account, totalReleasable);
    emit ReleaseToken(account, totalReleasable);
  }

  function lockedDetailsOf(address account) public view returns (LockInfo[] memory) {
    uint256 len = _lockedDetails[account].length;
    LockInfo[] memory items = new LockInfo[](len);
    for (uint256 i = 0; i < len; i++) {
      LockInfo storage currentItem = _lockedDetails[account][i];
      items[i] = currentItem;
    }
    return items;
  }

  function lockedBalanceOf(address account) public view returns (uint256) {
    return _lockedBalances[account];
  }

  function decimals() public pure override(ERC20) returns (uint8) {
    return 0;
  }

  constructor() ERC20("DAGEN lifeDAO", "DAGEN") {
    _mint(msg.sender, initSupply);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}
