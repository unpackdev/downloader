// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";

contract FayreTokenLocker is Ownable {
    struct LockData {
        uint256 lockId;
        address owner;
        uint256 amount;
        uint256 start;
        uint256 expiration;
    }

    event Lock(address indexed owner, uint256 indexed lockId, uint256 indexed amount, LockData lockData);
    event Withdraw(address indexed owner, uint256 indexed lockId, uint256 indexed amount, LockData lockData);

    address public tokenAddress;
    mapping(uint256 => LockData) public locksData;
    mapping(address => LockData) public usersLockData;
    uint256 public minLockDuration;

    uint256 private _currentLockId;

    function setTokenAddress(address newTokenAddress) external onlyOwner {
        tokenAddress = newTokenAddress;
    }

    function setMinLockDuration(uint256 newMinLockDuration) external onlyOwner {
        minLockDuration = newMinLockDuration;
    }

    function lock(uint256 amount, uint256 expiration) external {
        require(amount > 0, "Invalid amount");
        require(expiration >= block.timestamp + minLockDuration, "Expiration is too short");

        LockData storage lockData = usersLockData[msg.sender];

        require(lockData.amount == 0, "A lock is already present");

        lockData.lockId = _currentLockId++;
        lockData.owner = msg.sender;
        lockData.amount = amount;
        lockData.start = block.timestamp;
        lockData.expiration = expiration;

        locksData[lockData.lockId] = lockData;

        _transferAsset(msg.sender, address(this), amount);

        emit Lock(msg.sender, lockData.lockId, amount, lockData);
    }

    function withdraw() external {
        LockData storage lockData = usersLockData[msg.sender];

        require(lockData.amount > 0, "Already withdrawed");
        require(lockData.expiration < block.timestamp, "Lock not expired");

        uint256 amountToTransfer = lockData.amount;

        lockData.amount = 0;

        locksData[lockData.lockId] = lockData;

        _transferAsset(address(this), msg.sender, amountToTransfer);

        emit Withdraw(msg.sender, lockData.lockId, amountToTransfer, lockData);
    }

    function _transferAsset(address from, address to, uint256 amount) private {
        if (from == address(this))
            require(IERC20(tokenAddress).transfer(to, amount), "Error during transfer");
        else
            require(IERC20(tokenAddress).transferFrom(from, to, amount), "Error during transfer");
    }
}