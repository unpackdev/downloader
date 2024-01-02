// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract GTACoin is ERC20, Ownable {
    using SafeMath for uint256;

    // Addresses to receive tokens
    address public constant address1 = 0xd1cC4546bceD011CBE79A67E97078212f4F2d8F5;
    address public constant address2 = 0x603279057feE011Bf87FA23E54Ef77b3EF098B8F;
    address public constant address3 = 0x4D0F376ad58e0897c9bD7C12FD5BbC9Ab8b1ee8f;
    address public constant address4 = 0x468c0BC408387c3E0f3f23847e8461315553DDfa;
    address public constant address5 = 0x553A00D24e103a426f8beed2e6c7D36f22C88Cf9;

    // Locking information
    mapping(address => uint256) public lockEndTime;

    // Event to notify token lock
    event TokensLocked(address indexed account, uint256 amount, uint256 unlockTime);

    // Constructor
    constructor() ERC20("GTA Coin", "GTA") Ownable(msg.sender) {
        // Total supply is 2 billion (2,000,000,000) tokens with 18 decimals
        _mint(msg.sender, 2000000000 * 10**18);

        // Send tokens to specified addresses and lock tokens for address1 from today
        sendTokensWithDynamicLock(address1, 200000000 * 10**18, calculateLockDuration(26, 11, 2024));
        sendTokensWithDynamicLock(address2, 200000000 * 10**18, 0); // No lock for address2
        sendTokensWithDynamicLock(address3, 400000000 * 10**18, 0); // No lock for address3
        sendTokensWithDynamicLock(address4, 200000000 * 10**18, 0); // No lock for address4
        sendTokensWithDynamicLock(address5, 1000000000 * 10**18, 0); // No lock for address5
        
    }

    // Send tokens to a specified address and lock them for a specific duration
    function sendTokensWithDynamicLock(address to, uint256 amount, uint256 lockDuration) internal onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");

        _transfer(msg.sender, to, amount);

        // Set lock end time based on the current timestamp and dynamic lock duration
        if (lockDuration > 0) {
            lockEndTime[to] = block.timestamp + lockDuration;
            // Emit an event to notify the lock
            emit TokensLocked(to, amount, lockEndTime[to]);
        }
    }

    // Function to retrieve locked status and lock end time for an address
    function getLockStatus(address account) external view returns (bool isLocked, uint256 endTime) {
        return (block.timestamp < lockEndTime[account], lockEndTime[account]);
    }

    // Function to calculate lock duration in seconds given a specific date
    function calculateLockDuration(uint256 day, uint256 month, uint256 year) internal view returns (uint256) {
        uint256 lockEndDate = block.timestamp;

        // Calculate the timestamp for the specified date
        lockEndDate = lockEndDate.add(day * 1 days);
        lockEndDate = lockEndDate.add((month - 1) * 30 days);
        lockEndDate = lockEndDate.add((year - 1970) * 365 days);

        // Return the lock duration in seconds
        return lockEndDate - block.timestamp;
    }

    // Additional functions as needed...
}
