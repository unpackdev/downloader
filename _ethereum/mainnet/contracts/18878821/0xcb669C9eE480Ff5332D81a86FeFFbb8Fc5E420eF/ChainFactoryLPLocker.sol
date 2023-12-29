/**
 *Submitted for verification at Etherscan.io on 2023-12-13
*/

/**
 *Submitted for verification at Etherscan.io on 2023-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

abstract contract LPAccessControl {
    address public owner;
    mapping(address => bool) public liquidityProviders;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyLiquidityProvider() {
        require(liquidityProviders[msg.sender] == true, "Not a liquidity provider");
        _;
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title UpfrontReentrancyGuard
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting contracts must use the `nonReentrant` modifier on functions or
 * external calls that should be protected against reentrancy attacks.
 *
 * When the `nonReentrant` modifier is used, the function execution will be
 * halted if a reentrant call is detected, thereby guarding against such attacks.
 */
abstract contract UpfrontReentrancyGuard {
    // Internal status variable to keep track of the call state.
    // It's set to 1 during contract construction, representing the non-reentrant state.
    // When a function with the `nonReentrant` modifier is called, `_status` will be set to 2.
    uint8 private _status;

    constructor () {
        _status = 1; // Initialize the contract in the non-reentrant state.
    }

    /**
     * @dev Modifier to prevent reentrant calls.
     * It will revert the transaction if a reentrant call is detected.
     *
     * This modifier checks if the current call status is `1` (non-reentrant),
     * sets the status to `2` to represent an ongoing call, and then reverts it back to `1`
     * once the function call is completed.
     */
    modifier nonReentrant() {
        // If the status is 2, a reentrant call is detected, so we revert.
        require(_status != 2, "UpfrontReentrancyGuard: reentrant call");

        // Set the status to 2 to signal the start of a function execution.
        _status = 2;

        // Function execution is placed here by the `_;` placeholder.
        _;

        // Set the status back to 1 to indicate the end of a function execution.
        _status = 1;
    }
}

contract ChainFactoryLPLocker is LPAccessControl, UpfrontReentrancyGuard {
    struct LockInfo {
        address lpToken;
        uint256 amount;
        uint256 unlockTime;
        uint256 initialLockDuration;
        uint256[] relockTimestamps;
    }

    IERC20 public lpToken;
    address payable public feeWallet;
    uint256 public feePercentage = 7; // 0.7% in basis points
    uint256 public relockFeePercentage = 5; // 0.5% in basis points
    uint256[9] public lockDurations = [30 days, 90 days, 180 days, 270 days, 360 days, 540 days, 720 days, 900 days, 1080 days];

    mapping(address => LockInfo) public locks;
    mapping(address => address[]) public lpTokenLocks;

    //event logs for front end
    event LPlocked(address indexed user, address indexed lpToken, uint256 amount, uint256 lockDuration, uint256 unlockTime);
    event Relock(address indexed user, address indexed lpToken, uint256 newLockDuration, uint256 newUnlockTime, uint256 relockFee);
    event Withdrawal(address indexed user, address indexed lpToken, uint256 amount);

    constructor(address payable _feeWallet) {
        feeWallet = _feeWallet;
    }

    function lockLP(address _lpToken, uint256 amount, uint8 durationIndex) external payable nonReentrant {
    // Check if the correct fee is sent
    require(msg.value == 0.05 ether, "Fee of 0.05 ETH not sent");
    
    // Validate the duration index
    require(durationIndex < 9, "Invalid duration index");

    // Transfer the fee to the fee wallet
    feeWallet.transfer(msg.value);

    // Calculate and transfer the fee based on the amount being locked
    uint256 fee = (amount * feePercentage) / 1000;
    uint256 depositAmount = amount - fee;

    // Transfer the deposit amount and fee from the sender to the respective addresses
    IERC20(_lpToken).transferFrom(msg.sender, address(this), depositAmount);
    IERC20(_lpToken).transferFrom(msg.sender, feeWallet, fee);

    // Add the sender to the list of users who locked this LP token
    lpTokenLocks[_lpToken].push(msg.sender);

    // Update the lock information in the locks mapping
    locks[msg.sender] = LockInfo({
        lpToken: _lpToken,
        amount: depositAmount,
        unlockTime: block.timestamp + lockDurations[durationIndex],
        initialLockDuration: lockDurations[durationIndex],
        relockTimestamps: new uint256[](0)
    });

        // Mark the sender as a liquidity provider
        liquidityProviders[msg.sender] = true;

        // Emit an event for the lock
        emit LPlocked(msg.sender, _lpToken, depositAmount, lockDurations[durationIndex], block.timestamp + lockDurations[durationIndex]);
    }


    function withdraw() external onlyLiquidityProvider nonReentrant {
        LockInfo storage userLock = locks[msg.sender];
        require(block.timestamp > userLock.unlockTime, "Tokens are still locked");

        uint256 amount = userLock.amount;
        userLock.amount = 0;

        IERC20(userLock.lpToken).transfer(msg.sender, amount);

        liquidityProviders[msg.sender] = false; // Remove the LP role after withdrawal

        emit Withdrawal(msg.sender, userLock.lpToken, amount);
    }

    function relock(uint8 newDurationIndex) external onlyLiquidityProvider nonReentrant {
        require(newDurationIndex > 0, "Invalid duration index"); // Ensure new duration index is greater than 0
        require(newDurationIndex < 9, "Invalid duration index");

        LockInfo storage userLock = locks[msg.sender];
        require(block.timestamp < userLock.unlockTime, "Tokens are not currently locked or the lock period has expired");

        uint256 relockFee = (userLock.amount * relockFeePercentage) / 1000;
        userLock.amount -= relockFee;

        IERC20(userLock.lpToken).transfer(feeWallet, relockFee);

        userLock.unlockTime = block.timestamp + lockDurations[newDurationIndex];
        userLock.initialLockDuration = lockDurations[newDurationIndex];

        userLock.relockTimestamps.push(block.timestamp);

        emit Relock(msg.sender, userLock.lpToken, lockDurations[newDurationIndex], block.timestamp + lockDurations[newDurationIndex], relockFee);
    }

    function getLockDetails(address user) external view returns (uint256 lockDuration, uint256 timeLeft, uint256 amountLocked, uint256[] memory relockTimes, address lpTokenAddress) {
        if (locks[user].amount == 0) return (0, 0, 0, new uint256[](0), address(0));

        return (
            locks[user].initialLockDuration,
            locks[user].unlockTime > block.timestamp ? locks[user].unlockTime - block.timestamp : 0,
            locks[user].amount,
            locks[user].relockTimestamps,
            locks[user].lpToken  // Return the address of the LP token
        );
    }

    function isLPTokenLocked(address _lpToken) external view returns (bool isLocked, uint256 timeLeft) {
        for (uint i = 0; i < lpTokenLocks[_lpToken].length; i++) {
            LockInfo storage lockInfo = locks[lpTokenLocks[_lpToken][i]];
            if (lockInfo.amount > 0 && block.timestamp < lockInfo.unlockTime) {
                return (true, lockInfo.unlockTime - block.timestamp);
            }
        }
        return (false, 0);
    }

    function getUsersWhoLockedToken(address _lpToken) external view returns (address[] memory) {
        return lpTokenLocks[_lpToken];
    }
 
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        LockInfo storage lockInfo = locks[msg.sender];  // Use the sender's address as the key

        // Check if the lock period has expired and the recovered token matches the LP token
        require(lockInfo.unlockTime <= block.timestamp && lockInfo.lpToken == tokenAddress, "Tokens are still locked or LP token mismatch");

        // Perform the ERC20 token recovery
        IERC20(tokenAddress).transfer(owner, amount);
    }

    function recoverEther(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}