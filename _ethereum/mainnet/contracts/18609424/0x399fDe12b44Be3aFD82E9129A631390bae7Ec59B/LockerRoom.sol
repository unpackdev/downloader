// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Carbon21.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface ITokenDetails {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract LockerRoom is Ownable, ReentrancyGuard {
    struct Locker {
        uint256 amount;
        uint256 lockUntil;
    }

    address public lockerManager;

    mapping(address => mapping(address => Locker[])) public lockers;
    mapping(address => address[]) public usersLockingToken;
    address[] public registeredTokens;

    event TokensLocked(address indexed user, address indexed tokenAddress, uint256 amount, uint256 lockTime, uint256 lockerIndex);
    event LockTimeAndTokensAdded(address indexed user, address indexed tokenAddress, uint256 additionalAmount, uint256 addedTime, uint256 lockerIndex);
    event TokensWithdrawn(address indexed user, address indexed tokenAddress, uint256 amount, uint256 lockerIndex);
    event TokensBurnt(address indexed user, address indexed tokenAddress, uint256 amount, uint256 lockerIndex);
    event TokenRegistered(address indexed tokenAddress);

    modifier onlyLockerManager() {
        require(msg.sender == lockerManager, "Caller is not the LockerManager");
        _;
    }

    constructor() {
        lockerManager = msg.sender;
    }

    function registerToken(address tokenAddress) external onlyLockerManager {
        require(!isRegistered(tokenAddress), "Token already registered");
        registeredTokens.push(tokenAddress);
        emit TokenRegistered(tokenAddress);
    }

    function changeLockerManager(address newLockerManager) external onlyOwner {
        lockerManager = newLockerManager;
    }

    function getRegisteredTokens() external view returns (address[] memory, string[] memory, string[] memory) {
        string[] memory names = new string[](registeredTokens.length);
        string[] memory symbols = new string[](registeredTokens.length);

        for (uint256 i = 0; i < registeredTokens.length; i++) {
            ITokenDetails token = ITokenDetails(registeredTokens[i]);
            names[i] = token.name();
            symbols[i] = token.symbol();
        }

        return (registeredTokens, names, symbols);
    }

    function isRegistered(address tokenAddress) public view returns (bool) {
        for (uint256 i = 0; i < registeredTokens.length; i++) {
            if (registeredTokens[i] == tokenAddress) {
                return true;
            }
        }
        return false;
    }

    function userAlreadyLockingToken(address tokenAddress, address user) internal view returns (bool) {
        address[] memory users = usersLockingToken[tokenAddress];
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == user) {
                return true;
            }
        }
        return false;
    }

    function lockTokens(address tokenAddress, address minterAddress, uint256 amount, uint256 lockTimeInBlocks) external returns (uint256, uint256) {
        require(amount > 0, "Amount should be greater than 0");
        require(isRegistered(tokenAddress), "Token not registered");
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(minterAddress, address(this), amount), "Transfer failed");

        Locker memory newLocker;
        newLocker.amount = amount;
        newLocker.lockUntil = block.number + lockTimeInBlocks;

        lockers[minterAddress][tokenAddress].push(newLocker);

        if (!userAlreadyLockingToken(tokenAddress, minterAddress)) {
            usersLockingToken[tokenAddress].push(minterAddress);
        }
        emit TokensLocked(minterAddress, tokenAddress, amount, lockTimeInBlocks, lockers[minterAddress][tokenAddress].length - 1);

        return (newLocker.amount, lockTimeInBlocks);
    }

    function addLockAndTime(address tokenAddress, address minterAddress, uint256 additionalAmount, uint256 additionalBlocks, uint256 lockerIndex) external returns (uint256 newAmount, uint256 newLockTime) {
        require(lockerIndex < lockers[minterAddress][tokenAddress].length, "Invalid locker index");
        Locker storage locker = lockers[minterAddress][tokenAddress][lockerIndex];
        require(locker.amount > 0, "No tokens locked");
        IERC20 token = IERC20(tokenAddress);
        
        // If additionalAmount is greater than 0, transfer the tokens and add to the locker's amount
        if (additionalAmount > 0) {
            require(token.transferFrom(minterAddress, address(this), additionalAmount), "Transfer failed");
            locker.amount += additionalAmount;
        }

        // Adjust the lock time
        if (locker.lockUntil < block.number) {
            locker.lockUntil = block.number + additionalBlocks;
        } else {
            locker.lockUntil += additionalBlocks;
        }

        emit LockTimeAndTokensAdded(minterAddress, tokenAddress, additionalAmount, additionalBlocks, lockerIndex);

        return (locker.amount, (locker.lockUntil - block.number));
    }

    function withdrawAllFrom(address tokenAddress) external nonReentrant {
        require(isRegistered(tokenAddress), "Token not registered");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < lockers[msg.sender][tokenAddress].length; i++) {
            if (block.number > lockers[msg.sender][tokenAddress][i].lockUntil) {
                totalAmount += lockers[msg.sender][tokenAddress][i].amount;
                lockers[msg.sender][tokenAddress][i] = Locker(0, 0);
            }
        }

        require(totalAmount > 0, "No tokens to withdraw");
        
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, totalAmount), "Transfer failed");

        emit TokensWithdrawn(msg.sender, tokenAddress, totalAmount, 0); // Using 0 as index because we are not withdrawing from a specific locker
    }

    function withdrawLocker(address tokenAddress, uint256 lockerIndex) external nonReentrant {
        require(lockerIndex < lockers[msg.sender][tokenAddress].length, "Invalid locker index");
        Locker storage locker = lockers[msg.sender][tokenAddress][lockerIndex];
        require(locker.amount > 0, "Locker already emptied");
        require(block.number > locker.lockUntil, "Tokens are still locked");
        
        uint256 amount = locker.amount;
        locker.amount = 0;
        locker.lockUntil = 0;

        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Transfer failed");

        emit TokensWithdrawn(msg.sender, tokenAddress, amount, lockerIndex);
    }

    function burnLocker(address tokenAddress, uint256 lockerIndex) external nonReentrant {
        require(lockerIndex < lockers[msg.sender][tokenAddress].length, "Invalid locker index");
        Locker storage locker = lockers[msg.sender][tokenAddress][lockerIndex];
        require(locker.amount > 0, "Locker already emptied");
        
        uint256 amount = locker.amount;
        locker.amount = 0;
        locker.lockUntil = 0;

        Carbon21 token = Carbon21(tokenAddress);
        token.burn(amount);

        emit TokensBurnt(msg.sender, tokenAddress, amount, lockerIndex);
    }

    function getLockersFrom(address userAddress) external view returns (address[] memory tokens, uint256[] memory amounts, uint256[] memory lockDurations) {
        uint256 count = 0;
        for (uint256 j = 0; j < registeredTokens.length; j++) {
            count += lockers[userAddress][registeredTokens[j]].length;
        }

        tokens = new address[](count);
        amounts = new uint256[](count);
        lockDurations = new uint256[](count);

        uint256 index = 0;
        for (uint256 j = 0; j < registeredTokens.length; j++) {
            address tokenAddress = registeredTokens[j];
            for (uint256 i = 0; i < lockers[userAddress][tokenAddress].length; i++) {
                tokens[index] = tokenAddress;
                amounts[index] = lockers[userAddress][tokenAddress][i].amount;
                lockDurations[index] = lockers[userAddress][tokenAddress][i].lockUntil > block.number
                    ? lockers[userAddress][tokenAddress][i].lockUntil - block.number
                    : 0;
                index++;
            }
        }
        return (tokens, amounts, lockDurations);
    }

    function getLocked(address tokenAddress) external view returns (uint256) {
        return _getLockedAtBlock(tokenAddress, block.number);
    }

    function getLockedAtBlock(address tokenAddress, uint256 _blockNumber) external view returns (uint256) {
        return _getLockedAtBlock(tokenAddress, _blockNumber);
    }

    function _getLockedAtBlock(address tokenAddress, uint256 _blockNumber) internal view returns (uint256) {
        uint256 totalLocked = 0;
        
        address[] memory users = usersLockingToken[tokenAddress];
        for (uint256 j = 0; j < users.length; j++) {
            address userAddress = users[j];
            for (uint256 i = 0; i < lockers[userAddress][tokenAddress].length; i++) {
                if(lockers[userAddress][tokenAddress][i].lockUntil > _blockNumber) {
                    totalLocked += lockers[userAddress][tokenAddress][i].amount;
                }
            }
        }
        
        return totalLocked;
    }

}