// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./Pausable.sol";

import "./ILockSubscription.sol";

contract LockSubscription is Ownable, Pausable, ILockSubscription {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal lockSubscribers;
    EnumerableSet.AddressSet internal unlockSubscribers;
    address public eventSource;

    modifier onlyEventSource() {
        require(msg.sender == eventSource, "!eventSource");
        _;
    }

    function lockSubscribersCount() public view returns (uint256) {
        return lockSubscribers.length();
    }

    function unlockSubscribersCount() public view returns (uint256) {
        return unlockSubscribers.length();
    }

    function lockSubscriberAt(uint256 index) public view returns (address) {
        return lockSubscribers.at(index);
    }

    function unlockSubscriberAt(uint256 index) public view returns (address) {
        return unlockSubscribers.at(index);
    }

    function setEventSource(address _eventSource) public onlyOwner {
        require(_eventSource != address(0), "zeroAddress");
        eventSource = _eventSource;
    }

    function addLockSubscriber(address s) external onlyOwner {
        require(s != address(0), "zeroAddress");
        lockSubscribers.add(s);
    }

    function addUnlockSubscriber(address s) external onlyOwner {
        require(s != address(0), "zeroAddress");
        unlockSubscribers.add(s);
    }

    function removeUnlockSubscriber(address s) external onlyOwner {
        unlockSubscribers.remove(s);
    }

    function removeLockSubscriber(address s) external onlyOwner {
        lockSubscribers.remove(s);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function processLockEvent(
        address account,
        uint256 lockStart,
        uint256 lockEnd,
        uint256 amount
    ) external override onlyEventSource whenNotPaused {
        uint256 count = lockSubscribers.length();
        if (count != 0) {
            for (uint64 i = 0; i < count; i++) {
                ILockSubscription(lockSubscribers.at(i)).processLockEvent(
                    account,
                    lockStart,
                    lockEnd,
                    amount
                );
            }
        }
    }

    function processWitdrawEvent(
        address account,
        uint256 amount
    ) external override onlyEventSource whenNotPaused {
        uint256 count = unlockSubscribers.length();
        if (count != 0) {
            for (uint64 i = 0; i < count; i++) {
                ILockSubscription(unlockSubscribers.at(i)).processWitdrawEvent(
                    account,
                    amount
                );
            }
        }

    }
}
