
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract GuildOwnable {
    address internal __owner;
    address internal __backup;
    uint256 internal __lastOwnerUsage;
    uint256 internal __backupActivationWait;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BackupTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function setBackupActivationWait(uint256 _backupActivationWait) public onlyOwner {
        __backupActivationWait = _backupActivationWait;
        _activity();
    }

    function owner() public view returns (address) {
        return __owner;
    }

    function backupOwner() public view returns (address) {
        return __backup;
    }

    function isBackupActive() public view returns (bool) {
        if (__backup == address(0x0)) {
            return false;
        }
        if ((__lastOwnerUsage + __backupActivationWait) <= block.timestamp) {
            return true;
        }

        return false;
    }

    function isOwnerOrActiveBackup(address _addr) public view returns (bool) {
        return (_addr == owner() ||
            (isBackupActive() && (_addr == backupOwner()))
        );
    }

    modifier onlyOwnerOrActiveBackup() {
        require(isOwnerOrActiveBackup(msg.sender), "Ownable: caller is not owner or active backup");
        _;
    }

    modifier onlyOwnerOrBackup() {
        require(msg.sender == __owner || msg.sender == __backup, "Ownable: caller is not owner or backup");
        _;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function transferBackup(address newBackup) public onlyOwnerOrBackup {
        if (newBackup == address(0)) {
            require(msg.sender == __owner, "Ownable: new backup is the zero address");
        }

        _transferBackup(newBackup);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = __owner;
        __owner = newOwner;
        _activity();
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _transferBackup(address newBackup) internal {
        address oldBackup = __backup;
        __backup = newBackup;
        _activity();
        emit BackupTransferred(oldBackup, newBackup);
    }

    function _activity() internal {
        if (msg.sender == __owner) {
            __lastOwnerUsage = block.timestamp;
        }
    }
}
