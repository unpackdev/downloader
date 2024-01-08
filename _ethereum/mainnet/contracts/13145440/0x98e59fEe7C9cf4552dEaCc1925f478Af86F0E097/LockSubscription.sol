pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./Pausable.sol";

import "./ILockSubscription.sol";
import "./ILockSubscriber.sol";

contract LockSubscription is Ownable, Pausable, ILockSubscription {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal subscribers;
    address public eventSource;

    modifier onlyEventSource() {
        require(msg.sender == eventSource, "!eventSource");
        _;
    }

    function subscribersCount() public view returns (uint256) {
        return subscribers.length();
    }

    function subscriberAt(uint256 index) public view returns (address) {
        return subscribers.at(index);
    }

    function setEventSource(address _eventSource) public onlyOwner {
        require(_eventSource != address(0), "zeroAddress");
        eventSource = _eventSource;
    }

    function addSubscriber(address s) external onlyOwner {
        require(s != address(0), "zeroAddress");
        subscribers.add(s);
    }

    function removeSubscriber(address s) external onlyOwner {
        subscribers.remove(s);
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
        uint256 count = subscribers.length();
        if (count != 0) {
            for (uint64 i = 0; i < count; i++) {
                ILockSubscriber(subscribers.at(i)).processLockEvent(
                    account,
                    lockStart,
                    lockEnd,
                    amount
                );
            }
        }
    }
}
