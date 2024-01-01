// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/*
            ██████                                                                                  
           ████████         █████████     ██████████     ███  ████         ███                      
            ██████        █████████████ ██████████████   ████ ██████      ████                      
              ██        ████████  ████ ██████    ██████  ████ ███████     ████                      
              ██       █████          █████        █████ ████ █████████   ████                      
              ██       █████          ████         █████ ████ ████ ██████ ████                      
             ████      █████          ████         █████ ████ ████  ██████████                      
            █████       █████         █████        █████ ████ ████    ████████                      
           ████████      █████████████ ████████████████  ████ ████     ███████                      
          ████  ████      █████████████  ████████████    ████ ████       █████                      
        █████    █████        █████          ████                                                   
      ██████      ██████                                                                            
    ██████         ███████                                                                          
  ████████          ████████           ███████████  █████████████████        ████  ████ ████████████
 ████████           █████████        █████████████  ███████████████████      ████ █████ ████████████
█████████           ██████████     ███████          █████        ████████    ████ █████ ████        
██████████         ████████████    █████            █████        █████████   ████ █████ ████        
██████████████   ██████████████    █████   ████████ ████████████ ████ ██████ ████ █████ ███████████ 
███████████████████████████████    █████   ████████ ██████████   ████  ██████████ █████ ██████████  
███████████████████████████████    ██████      ████ █████        ████    ████████ █████ ████        
 █████████████████████████████      ███████████████ ████████████ ████      ██████ █████ ████████████
  ██████████████████████████          █████████████ █████████████████       █████ █████ ███████████
*/

import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Migrator.sol";

/// @title LiquidityLocker
/// @author @neuro_0x
/// @dev A contract for locking Uniswap V2 liquidity pool tokens for specified periods
contract LiquidityLocker is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev The fee amount to use
    uint256 public fee;
    /// @dev The address to send fees to
    address public feeRecipient;

    /// @dev The Uniswap V2 factory address
    IUniswapV2Factory private constant _UNISWAP_V2_FACTORY =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    /// @dev The user struct records all the locked tokens for a user
    struct User {
        EnumerableSet.AddressSet lockedTokens; // records all tokens the user has locked
        mapping(address => uint256[]) locksForToken; // map erc20 address to lock id for that token
    }

    /// @dev The token lock struct records all the data for a lock
    struct TokenLock {
        uint256 lockDate; // the date the token was locked
        uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
        uint256 initialAmount; // the initial lock amount
        uint256 unlockDate; // the date the token can be withdrawn
        uint256 lockID; // lockID nonce per uni pair
        address owner;
    }

    /// @dev A mapping of user addresses to User structs
    mapping(address userAddress => User user) private _users;

    /// @dev A set of all locked tokens
    EnumerableSet.AddressSet private _lockedTokens;
    /// @dev A mapping of univ2 pair addresses to TokenLock structs
    mapping(address pair => TokenLock[] locks) public tokenLocks; // map univ2 pair to all its locks

    /// @dev The migrator contract which allows locked lp tokens to be migrated to uniswap v3
    IUniswapV2Migrator public migrator;

    /////////////////////////////////////////////////////////////////
    //                           Events                            //
    /////////////////////////////////////////////////////////////////

    /// @notice Emitted when the fee is set
    /// @param fee - The fee amount
    event FeeSet(uint256 indexed fee);
    /// @notice Emitted when the migrator is set
    /// @param migrator - The address of the migrator contract
    event MigratorSet(address indexed migrator);
    /// @notice Emitted when the fee recipient is set
    /// @param feeRecipient - The address of the fee recipient
    event FeeRecipientSet(address indexed feeRecipient);
    /// @notice Emitted when the lock ownership is transferred
    /// @param newOwner - The address of the new owner
    event LockOwnershipTransfered(address indexed newOwner);
    /// @notice Emitted when tokens are withdrawn
    /// @param lpToken - The address of the LP token
    /// @param amount - The amount of tokens withdrawn
    event OnWithdraw(address indexed lpToken, uint256 indexed amount);
    /// @notice Emitted when tokens are migrated
    /// @param user - The address of the user
    /// @param lpToken - The address of the LP token
    /// @param amount - The amount of tokens migrated
    event Migrated(address indexed user, address indexed lpToken, uint256 indexed amount);
    /// @notice Emitted when the lock is relocked
    /// @param user - The address of the user
    /// @param lpToken - The address of the LP token
    /// @param unlockDate - The unlock date of the lock
    event OnRelock(address indexed user, address indexed lpToken, uint256 indexed unlockDate);
    /// @notice Emitted when tokens are deposited
    /// @param lpToken - The address of the LP token
    /// @param user - The address of the user
    /// @param amount - The amount of tokens deposited
    /// @param lockDate - The lock date of the lock
    /// @param unlockDate - The unlock date of the lock
    event OnDeposit(
        address lpToken, address indexed user, uint256 amount, uint256 indexed lockDate, uint256 indexed unlockDate
    );

    /////////////////////////////////////////////////////////////////
    //                           Errors                            //
    /////////////////////////////////////////////////////////////////

    /// @notice Reverts when the lock is a mismatch
    error LockMismatch();
    /// @notice Reverts when the amount is invalid
    error InvalidAmount();
    /// @notice Reverts when the migrator is not set
    error MigratorNotSet();
    /// @notice Reverts when the lock date is invalid
    error InvalidLockDate();
    /// @notice Reverts when the owner is already set
    error OwnerAlreadySet();
    /// @notice Reverts when the recipient is already set
    error InvalidRecipient();
    /// @notice Reverts when the lock is before the unlock date
    error BeforeUnlockDate();
    /// @notice Reverts when the LP Token is not a univ2 pair
    /// @param lpToken The address of the LP token
    error NotUniPair(address lpToken);
    /// @notice Reverts when the transfer fails
    /// @param amount - The amount being transferred
    /// @param from - The address the transfer is from
    /// @param to - The address the transfer is to
    error TransferFailed(uint256 amount, address from, address to);

    /// @dev Creates a new LiquidityLocker contract
    /// @param _fee The fee amount to use
    /// @param _feeRecipient The address to send fees to
    constructor(uint256 _fee, address _feeRecipient) payable {
        fee = _fee;
        feeRecipient = _feeRecipient;
    }

    /////////////////////////////////////////////////////////////////
    //                       Public/External                       //
    /////////////////////////////////////////////////////////////////

    /// @dev Set the fee amount
    /// @param amount The fee amount to use
    function setFee(uint256 amount) external onlyOwner {
        fee = amount;
        emit FeeSet(amount);
    }

    /// @dev Set the fee recipient
    /// @param feeRecipient_ The address to send fees to
    function setFeeRecipient(address feeRecipient_) external onlyOwner {
        feeRecipient = feeRecipient_;
        emit FeeRecipientSet(feeRecipient_);
    }

    /// @dev Set the migrator contract which allows locked lp tokens to be migrated to uniswap v3
    /// @param _migrator The address of the migrator contract
    function setMigrator(IUniswapV2Migrator _migrator) external onlyOwner {
        migrator = _migrator;
        emit MigratorSet(address(_migrator));
    }

    /// @dev Creates a new lock
    /// @param lpToken the univ2 token address
    /// @param amountOfLPToLock amount of LP tokens to lock
    /// @param unlockDate the unix timestamp (in seconds) until unlock
    /// @param withdrawer the user who can withdraw liquidity once the lock expires
    /// @return tokenLock - the token lock object created
    function lockLPToken(
        IERC20 lpToken,
        uint256 amountOfLPToLock,
        uint256 unlockDate,
        address payable withdrawer
    )
        external
        payable
        nonReentrant
        returns (TokenLock memory tokenLock)
    {
        if (msg.value < fee) {
            revert InvalidAmount();
        }

        if (amountOfLPToLock == 0) {
            revert InvalidAmount();
        }

        if (unlockDate > 10_000_000_000) {
            revert InvalidLockDate();
        }

        // ensure this pair is a univ2 pair by querying the factory
        IUniswapV2Pair lpair = IUniswapV2Pair(address(lpToken));
        address factoryPairAddress = _UNISWAP_V2_FACTORY.getPair(lpair.token0(), lpair.token1());

        if (factoryPairAddress != address(lpToken)) {
            revert NotUniPair(address(lpToken));
        }

        SafeERC20.safeTransferFrom(lpToken, _msgSender(), address(this), amountOfLPToLock);

        tokenLock.lockDate = block.timestamp;
        tokenLock.amount = amountOfLPToLock;
        tokenLock.initialAmount = amountOfLPToLock;
        tokenLock.unlockDate = unlockDate;
        tokenLock.lockID = tokenLocks[address(lpToken)].length;
        tokenLock.owner = withdrawer;

        // record the lock for the univ2pair
        tokenLocks[address(lpToken)].push(tokenLock);
        _lockedTokens.add(address(lpToken));

        // record the lock for the user
        User storage user = _users[withdrawer];
        user.lockedTokens.add(address(lpToken));
        uint256[] storage userLocks = user.locksForToken[address(lpToken)];
        userLocks.push(tokenLock.lockID);

        (bool success,) = feeRecipient.call{ value: msg.value }("");
        if (!success) {
            revert TransferFailed(msg.value, address(this), feeRecipient);
        }

        emit OnDeposit(address(lpToken), _msgSender(), tokenLock.amount, tokenLock.lockDate, tokenLock.unlockDate);
    }

    /// @dev extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed this prevents
    /// errors when a user performs multiple tx per block possibly with varying gas prices
    /// @param _lpToken the univ2 token address
    /// @param _index the index of the lock for the token
    /// @param _lockID the lockID of the lock for the token
    /// @param _unlockDate the new unix timestamp (in seconds) until unlock
    function relock(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _unlockDate) external nonReentrant {
        if (_unlockDate > 10_000_000_000) {
            revert InvalidLockDate();
        }

        // timestamp entered in seconds
        uint256 lockID = _users[_msgSender()].locksForToken[address(_lpToken)][_index];
        TokenLock storage userLock = tokenLocks[address(_lpToken)][lockID];

        if (lockID != _lockID || userLock.owner != _msgSender()) {
            revert LockMismatch();
        }

        if (userLock.unlockDate > _unlockDate) {
            revert BeforeUnlockDate();
        }

        userLock.unlockDate = _unlockDate;
        emit OnRelock(_msgSender(), address(_lpToken), _unlockDate);
    }

    /// @dev withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed this
    /// prevents errors when a user performs multiple tx per block possibly with varying gas prices
    /// @param _lpToken the univ2 token address
    /// @param _index the index of the lock for the token
    /// @param _lockID the lockID of the lock for the token
    /// @param _amount the amount to withdraw
    function withdraw(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        if (_amount == 0) {
            revert InvalidAmount();
        }

        uint256 lockID = _users[_msgSender()].locksForToken[address(_lpToken)][_index];
        TokenLock storage userLock = tokenLocks[address(_lpToken)][lockID];

        if (lockID != _lockID || userLock.owner != _msgSender()) {
            revert LockMismatch();
        }

        if (userLock.unlockDate > block.timestamp) {
            revert BeforeUnlockDate();
        }

        userLock.amount = userLock.amount - _amount;

        // clean user storage
        if (userLock.amount == 0) {
            uint256[] storage userLocks = _users[_msgSender()].locksForToken[address(_lpToken)];
            userLocks[_index] = userLocks[userLocks.length - 1];
            userLocks.pop();
            if (userLocks.length == 0) {
                _users[_msgSender()].lockedTokens.remove(address(_lpToken));
            }
        }

        SafeERC20.safeTransfer(_lpToken, _msgSender(), _amount);
        emit OnWithdraw(address(_lpToken), _amount);
    }

    /// @dev increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees,
    /// and faster loading on our live block explorer
    /// @param _lpToken the univ2 token address
    /// @param _index the index of the lock for the token
    /// @param _lockID the lockID of the lock for the token
    /// @param _amount the amount to increment the lock by
    /// @return _userLock - the token lock object updated
    function incrementLock(
        IERC20 _lpToken,
        uint256 _index,
        uint256 _lockID,
        uint256 _amount
    )
        external
        nonReentrant
        returns (TokenLock memory _userLock)
    {
        if (_amount == 0) {
            revert InvalidAmount();
        }

        uint256 lockID = _users[_msgSender()].locksForToken[address(_lpToken)][_index];
        TokenLock storage userLock = tokenLocks[address(_lpToken)][lockID];

        if (lockID != _lockID || userLock.owner != _msgSender()) {
            revert LockMismatch();
        }

        SafeERC20.safeTransferFrom(_lpToken, address(_msgSender()), address(this), _amount);

        userLock.amount = userLock.amount + _amount;

        emit OnDeposit(address(_lpToken), _msgSender(), userLock.amount, userLock.lockDate, userLock.unlockDate);

        return userLock;
    }

    /// @dev transfer a lock to a new owner, e.g. presale project -> project owner
    /// @param _lpToken the univ2 token address
    /// @param _index the index of the lock for the token
    /// @param _lockID the lockID of the lock for the token
    /// @param _newOwner the address of the new owner
    function transferLockOwnership(
        address _lpToken,
        uint256 _index,
        uint256 _lockID,
        address payable _newOwner
    )
        external
    {
        if (_newOwner == owner()) {
            revert OwnerAlreadySet();
        }

        uint256 lockID = _users[_msgSender()].locksForToken[_lpToken][_index];
        TokenLock storage transferredLock = tokenLocks[_lpToken][lockID];

        if (lockID != _lockID || transferredLock.owner != _msgSender()) {
            revert LockMismatch();
        }

        // record the lock for the new Owner
        User storage user = _users[_newOwner];
        user.lockedTokens.add(_lpToken);

        uint256[] storage userLocks = user.locksForToken[_lpToken];
        userLocks.push(transferredLock.lockID);

        // remove the lock from the old owner
        uint256[] storage userLocks2 = _users[_msgSender()].locksForToken[_lpToken];
        userLocks2[_index] = userLocks2[userLocks2.length - 1];
        userLocks2.pop();

        if (userLocks2.length == 0) {
            _users[_msgSender()].lockedTokens.remove(_lpToken);
        }

        transferredLock.owner = _newOwner;
        emit LockOwnershipTransfered(_newOwner);
    }

    /// @dev migrates liquidity to uniswap v3
    /// @param _lpToken the univ2 token address
    /// @param _index the index of the lock for the token
    /// @param _lockID the lockID of the lock for the token
    /// @param _amount the amount to migrate
    function migrate(IERC20 _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        if (address(migrator) == address(0)) {
            revert MigratorNotSet();
        }

        if (_amount == 0) {
            revert InvalidAmount();
        }

        uint256 lockID = _users[_msgSender()].locksForToken[address(_lpToken)][_index];
        TokenLock storage userLock = tokenLocks[address(_lpToken)][lockID];

        if (lockID != _lockID || userLock.owner != _msgSender()) {
            revert LockMismatch();
        }

        userLock.amount = userLock.amount - _amount;

        // clean user storage
        if (userLock.amount == 0) {
            uint256[] storage userLocks = _users[_msgSender()].locksForToken[address(_lpToken)];
            userLocks[_index] = userLocks[userLocks.length - 1];
            userLocks.pop();
            if (userLocks.length == 0) {
                _users[_msgSender()].lockedTokens.remove(address(_lpToken));
            }
        }

        IERC20(_lpToken).approve(address(migrator), _amount);
        migrator.migrate(address(_lpToken), _amount, userLock.unlockDate, _msgSender(), block.timestamp + 1 days);
        emit Migrated(_msgSender(), address(_lpToken), _amount);
    }

    /// @dev Get the number of locks for a specific token.
    /// @param _lpToken The address of the LP token.
    function getNumLocksForToken(address _lpToken) external view returns (uint256) {
        return tokenLocks[_lpToken].length;
    }

    /// @dev Get the total number of locked tokens
    function getNumLockedTokens() external view returns (uint256) {
        return _lockedTokens.length();
    }

    /// @dev Get the address of a locked token at an index.
    /// @param _index The index of the token.
    function getLockedTokenAtIndex(uint256 _index) external view returns (address) {
        return _lockedTokens.at(_index);
    }

    /// @dev Get the number of tokens a user has locked.
    /// @param _user The address of the user.
    function getUserNumLockedTokens(address _user) external view returns (uint256) {
        User storage user = _users[_user];
        return user.lockedTokens.length();
    }

    /// @dev Get the token address a user has locked at an index.
    /// @param _user The address of the user.
    /// @param _index The index of the token.
    function getUserLockedTokenAtIndex(address _user, uint256 _index) external view returns (address) {
        User storage user = _users[_user];
        return user.lockedTokens.at(_index);
    }

    /// @dev Get the number of locks for a specific user and token.
    /// @param _user The address of the user.
    /// @param _lpToken The address of the LP token.
    function getUserNumLocksForToken(address _user, address _lpToken) external view returns (uint256) {
        User storage user = _users[_user];
        return user.locksForToken[_lpToken].length;
    }

    /// @dev Get the lock for a specific user and token at an index.
    /// @param _user The address of the user.
    /// @param _lpToken The address of the LP token.
    /// @param _index The index of the lock.
    /// @return The lock date.
    /// @return Amount of tokens locked.
    /// @return Initial amount of tokens locked.
    /// @return Unlock date of the lock.
    /// @return Lock ID of the lock.
    /// @return Owner of the lock.
    function getUserLockForTokenAtIndex(
        address _user,
        address _lpToken,
        uint256 _index
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, address)
    {
        uint256 lockID = _users[_user].locksForToken[_lpToken][_index];
        TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
        return (
            tokenLock.lockDate,
            tokenLock.amount,
            tokenLock.initialAmount,
            tokenLock.unlockDate,
            tokenLock.lockID,
            tokenLock.owner
        );
    }
}
