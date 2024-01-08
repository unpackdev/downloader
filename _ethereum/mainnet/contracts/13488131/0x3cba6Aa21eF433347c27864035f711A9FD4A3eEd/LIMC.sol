// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ILIMC.sol";
import "./ERC20Pausable.sol";
import "./AccessControl.sol";

contract LIMC is ILIMC, ERC20Pausable, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping (address => bool) public blacklist;

    mapping (address => uint256) public lockIndex;
    mapping (address => LockInfo[]) public userLocks;
    mapping (address => mapping (address => mapping (uint256 => uint256))) public allowanceLocked;
    uint256 private _totalSupplyLocked;
    mapping (address => uint256) private _lockedAmounts;

    struct LockInfo {
        uint256 amount;
        uint256 unlockTime;
        uint256 buyTime;
    }

    constructor() ERC20("LimCore", "LIMC") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function balanceOfSum(address account) external view override returns (uint256) {
        return super.balanceOf(account) + _lockedAmounts[account];
    }

    function balanceOfLocked(address account) external view override returns (uint256) {
        return _lockedAmounts[account] - _vision(account);
    }

    function userLocksLength(address account) external view override returns (uint256) {
        return userLocks[account].length;
    }

    function transferLocked(address to, uint256 index, uint256 amount) external override {
        _transferLocked(_msgSender(), to, index, amount);
    }

    function transferFromLocked(address from, address to, uint256 index, uint256 amount) external override {
        uint256 currentAllowance = allowanceLocked[from][_msgSender()][index];
        require(currentAllowance >= amount, "Not enough locked token allowance");
        _approveLocked(from, _msgSender(), index, currentAllowance - amount);
        _transferLocked(from, to, index, amount);
    }

    function approveLocked(address to, uint256 index, uint256 amount) external override {
        _approveLocked(_msgSender(), to, index, amount);
    }

    function increaseAllowanceLocked(address to, uint256 index, uint256 amount) external override {
        _approveLocked(_msgSender(), to, index, allowanceLocked[_msgSender()][to][index] + amount);
    }

    function decreaseAllowanceLocked(address to, uint256 index, uint256 amount) external override {
        uint256 currentAllowance = allowanceLocked[_msgSender()][to][index];
        require(currentAllowance >= amount, "Allowance would be below zero");
        _approveLocked(_msgSender(), to, index, currentAllowance - amount);
    }

    function pause() external override whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external override whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function addToBlacklist(address account) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!blacklist[account], "Account already blacklisted");
        blacklist[account] = true;
        emit BlacklistStatusChanged(account, true);
    }

    function removeFromBlacklist(address account) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(blacklist[account], "Account is not blacklisted");
        blacklist[account] = false;
        emit BlacklistStatusChanged(account, false);
    }

    function mint(address account, uint256 amount, uint256 lockTime) external override onlyRole(MINTER_ROLE) {
        if (lockTime == 0) {
            _mint(account, amount);
        }
        else {
            _beforeLockedTokenTransfer(address(0), account, amount);
            _totalSupplyLocked += amount;
            _lockedAmounts[account] += amount;
            userLocks[account].push(LockInfo(amount, block.timestamp + lockTime, block.timestamp));
            emit TransferLocked(address(0), account, amount);
        }
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() + _totalSupplyLocked;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) + _vision(account);
    }

    function unlock(address account, uint256 numberOfLocks) public override {
        require(_lockedAmounts[account] > 0, "No tokens locked");
        uint256 len = userLocks[account].length;
        uint256 i = lockIndex[account];
        uint256 toWrite = i;
        require(i + numberOfLocks <= len, "Cannot unlock this many records, exceeds length");
        if (numberOfLocks == 0) {
            numberOfLocks = len;
        }
        else {
            numberOfLocks += i;
        }
        uint256 toUnlockTotal = 0;
        for (i; i < numberOfLocks; i++) {
            if (block.timestamp >= userLocks[account][i].unlockTime) {
                toUnlockTotal += userLocks[account][i].amount;
                if (toWrite == i) {
                    delete userLocks[account][i];
                    toWrite = i+1;
                }
                else if (userLocks[account][i].amount != 0) {
                    userLocks[account][i].amount = 0;
                }
            }
        }
        lockIndex[account] = toWrite;
        if (toUnlockTotal > 0) {
            _lockedAmounts[account] -= toUnlockTotal;
            _totalSupplyLocked -= toUnlockTotal;
            emit TransferLocked(account, address(0), toUnlockTotal);
            _mint(account, toUnlockTotal);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(!blacklist[from], "Sender is blacklisted");
        require(!blacklist[to], "Recipient is blacklisted");
        require(amount > 0, "Amount cannot be zero");
        if (from != address(0) && super.balanceOf(from) < amount && _lockedAmounts[from] > 0) {
            unlock(from, 0);
        }
    }

    function _vision(address account) private view returns (uint256) {
        uint256 toUnlockTotal = 0;
        for (uint256 i = lockIndex[account]; i < userLocks[account].length; i++) {
            if (block.timestamp >= userLocks[account][i].unlockTime) {
                toUnlockTotal += userLocks[account][i].amount;
            }
        }
        return toUnlockTotal;
    }

    function _beforeLockedTokenTransfer(address from, address to, uint256 amount) whenNotPaused private {
        require(!blacklist[from], "Sender is blacklisted");
        require(!blacklist[to], "Recipient is blacklisted");
        require(amount > 0, "Amount cannot be zero");
        if (from != address(0) && _lockedAmounts[from] > 0) {
            unlock(from, 0);
        }
    }

    function _transferLocked(address from, address to, uint256 index, uint256 amount) private {
        require(from != address(0), "Cannot transfer from zero address");
        require(to != address(0), "Cannot transfer to zero address");
        _beforeLockedTokenTransfer(from, to, amount);
        require(index >= lockIndex[from] && index < userLocks[from].length, "This lock does not exist");
        uint256 currentAmount = userLocks[from][index].amount;
        uint256 currentUnlockTime = userLocks[from][index].unlockTime;
        require(currentAmount >= amount, "Not enough token to transfer");
        _lockedAmounts[from] -= amount;
        _lockedAmounts[to] += amount;
        userLocks[from][index].amount = currentAmount - amount;
        userLocks[to].push(LockInfo(amount, currentUnlockTime, userLocks[from][index].buyTime));
        emit TransferLocked(from, to, amount);
    }

    function _approveLocked(address from, address to, uint256 index, uint256 amount) private {
        require(from != address(0), "Cannot approve from zero address");
        require(to != address(0), "Cannot approve to zero address");
        require(index >= lockIndex[from] && index < userLocks[from].length, "This lock does not exist");
        allowanceLocked[from][to][index] = amount;
        emit ApprovalLocked(from, to, index, amount);
    }
}