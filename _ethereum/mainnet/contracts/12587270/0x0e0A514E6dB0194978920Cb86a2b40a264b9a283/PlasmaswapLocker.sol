// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IPlasmaswapPair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IPlasmaswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IMigrator {
    function migrate(address lpToken, uint256 amount, uint256 unlockDate, address owner) external returns (bool);
}

contract PlasmaswapLocker is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  IPlasmaswapFactory public plasmaswapFactory;

  struct UserInfo {
    EnumerableSet.AddressSet lockedTokens; // records all tokens the user has locked
    mapping(address => uint256[]) locksForToken; // map erc20 address to lock id for that token
  }

  struct TokenLock {
    uint256 lockDate; // the date the token was locked
    uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
    uint256 initialAmount; // the initial lock amount
    uint256 unlockDate; // the date the token can be withdrawn
    uint256 lockID; // lockID nonce per uni pair
    address owner;
  }

  mapping(address => UserInfo) private users;

  EnumerableSet.AddressSet private lockedTokens;
  mapping(address => TokenLock[]) public tokenLocks; //map pl-p  pair to all its locks
  
  struct FeeStruct {
    uint256 ethFee; // Small eth fee to prevent spam on the platform
    uint256 liquidityFee; // fee on pl-p  liquidity tokens
  }
    
  FeeStruct public gFees;
  EnumerableSet.AddressSet private feeWhitelist;
  
  address payable devaddr;
  
  IMigrator migrator;

  event onDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
  event onWithdraw(address lpToken, uint256 amount);

  constructor(IPlasmaswapFactory _plasmaswapFactory) public {
    devaddr = msg.sender;
    gFees.ethFee = 1e18;
    gFees.liquidityFee = 10; // 1%
    plasmaswapFactory = _plasmaswapFactory;
  }
  
  function setDev(address payable _devaddr) public onlyOwner {
    devaddr = _devaddr;
  }
  
  /**
   * @notice Set the migrator contract which allows locked lp tokens to be migrated to plasmaswap v3
   */
  function setMigrator(IMigrator _migrator) public onlyOwner {
    migrator = _migrator;
  }
  
  function setFees( uint256 _ethFee, uint256 _liquidityFee) public onlyOwner {
    gFees.ethFee = _ethFee;
    gFees.liquidityFee = _liquidityFee;
  }
  
  /**
   * @notice Whitelisted accounts dont pay flatrate fees on locking
   */
  function whitelistFeeAccount(address _user, bool _add) public onlyOwner {
    if (_add) {
      feeWhitelist.add(_user);
    } else {
      feeWhitelist.remove(_user);
    }
  }

  /**
   * @notice Creates a new lock
   * @param _lpToken The pl-p  token address
   * @param _amount Amount of LP tokens to lock
   * @param _unlock_date The unix timestamp (in seconds) until unlock
   * @param _withdrawer The user who can withdraw liquidity once the lock expires.
   */
  function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _withdrawer) external payable nonReentrant {
    require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
    require(_amount > 0, 'INSUFFICIENT');

    // Ensure this pair is a pl-p  pair by querying the factory
    IPlasmaswapPair lpair = IPlasmaswapPair(address(_lpToken));
    address factoryPairAddress = plasmaswapFactory.getPair(lpair.token0(), lpair.token1());
    require(factoryPairAddress == address(_lpToken), 'NOT P-LP');

    TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);
    
    // Flatrate fees
    if (!feeWhitelist.contains(msg.sender)) {
        uint256 ethFee = gFees.ethFee;
        require(msg.value == ethFee, 'FEE NOT MET');
        uint256 devFee = ethFee;
        devaddr.transfer(devFee);
    } else if (msg.value > 0){
      // Refund eth if a whitelisted member sent it by mistake
      msg.sender.transfer(msg.value);
    }
    
    // Percent fee
    uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(1000);
    TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
    uint256 amountLocked = _amount.sub(liquidityFee);

    TokenLock memory token_lock;
    token_lock.lockDate = block.timestamp;
    token_lock.amount = amountLocked;
    token_lock.initialAmount = amountLocked;
    token_lock.unlockDate = _unlock_date;
    token_lock.lockID = tokenLocks[_lpToken].length;
    token_lock.owner = _withdrawer;

    // Record the lock for the pl-p pair
    tokenLocks[_lpToken].push(token_lock);
    lockedTokens.add(_lpToken);

    // Record the lock for the user
    UserInfo storage user = users[_withdrawer];
    user.lockedTokens.add(_lpToken);
    uint256[] storage user_locks = user.locksForToken[_lpToken];
    user_locks.push(token_lock.lockID);
    
    emit onDeposit(_lpToken, msg.sender, token_lock.amount, token_lock.lockDate, token_lock.unlockDate);
  }
  
  /**
   * @notice Extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed
   * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
   */
  function relock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _unlock_date) external nonReentrant {
    require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    require(userLock.unlockDate < _unlock_date, 'UNLOCK BEFORE');
    
    uint256 liquidityFee = userLock.amount.mul(gFees.liquidityFee).div(1000);
    uint256 amountLocked = userLock.amount.sub(liquidityFee);
    
    userLock.amount = amountLocked;
    userLock.unlockDate = _unlock_date;

    // Send pl-p  fee to dev address
    TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
  }
  
  /**
   * @notice Withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
   * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
   */
  function withdraw (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO WITHDRAWL');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    require(userLock.unlockDate < block.timestamp, 'NOT YET');
    userLock.amount = userLock.amount.sub(_amount);
    
    // Clean user storage
    if (userLock.amount == 0) {
      uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
      userLocks[_index] = userLocks[userLocks.length-1];
      userLocks.pop();
      if (userLocks.length == 0) {
        users[msg.sender].lockedTokens.remove(_lpToken);
      }
    }
    
    TransferHelper.safeTransfer(_lpToken, msg.sender, _amount);
    emit onWithdraw(_lpToken, _amount);
  }
  
  /**
   * @notice Increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees, and faster loading on our live block explorer
   */
  function incrementLock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    
    TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);
    
    // Send pl-p  fee to dev address
    uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(1000);
    TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
    uint256 amountLocked = _amount.sub(liquidityFee);
    
    userLock.amount = userLock.amount.add(amountLocked);
    
    emit onDeposit(_lpToken, msg.sender, amountLocked, userLock.lockDate, userLock.unlockDate);
  }
  
  /**
   * @notice Split a lock into two seperate locks, useful when a lock is about to expire and youd like to relock a portion
   * and withdraw a smaller portion
   */
  function splitLock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external payable nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    
    require(msg.value == gFees.ethFee, 'FEE NOT MET');
    devaddr.transfer(gFees.ethFee);
    
    userLock.amount = userLock.amount.sub(_amount);
    
    TokenLock memory token_lock;
    token_lock.lockDate = userLock.lockDate;
    token_lock.amount = _amount;
    token_lock.initialAmount = _amount;
    token_lock.unlockDate = userLock.unlockDate;
    token_lock.lockID = tokenLocks[_lpToken].length;
    token_lock.owner = msg.sender;

    // Record the lock for the pl-p pair
    tokenLocks[_lpToken].push(token_lock);

    // Record the lock for the user
    UserInfo storage user = users[msg.sender];
    uint256[] storage user_locks = user.locksForToken[_lpToken];
    user_locks.push(token_lock.lockID);
  }
  
  /**
   * @notice Transfer a lock to a new owner, e.g. spaceport project -> project owner
   */
  function transferLockOwnership (address _lpToken, uint256 _index, uint256 _lockID, address payable _newOwner) external {
    require(msg.sender != _newOwner, 'OWNER');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage transferredLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && transferredLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    
    // Record the lock for the new Owner
    UserInfo storage user = users[_newOwner];
    user.lockedTokens.add(_lpToken);
    uint256[] storage user_locks = user.locksForToken[_lpToken];
    user_locks.push(transferredLock.lockID);
    
    // Remove the lock from the old owner
    uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
    userLocks[_index] = userLocks[userLocks.length-1];
    userLocks.pop();
    if (userLocks.length == 0) {
      users[msg.sender].lockedTokens.remove(_lpToken);
    }
    transferredLock.owner = _newOwner;
  }
  
  /**
   * @notice Migrates liquidity to plasmaswap 
   */
  function migrate (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
    require(address(migrator) != address(0), "NOT SET");
    require(_amount > 0, 'ZERO MIGRATION');
    
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    userLock.amount = userLock.amount.sub(_amount);
    
    // Clean user storage
    if (userLock.amount == 0) {
      uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
      userLocks[_index] = userLocks[userLocks.length-1];
      userLocks.pop();
      if (userLocks.length == 0) {
        users[msg.sender].lockedTokens.remove(_lpToken);
      }
    }
    
    TransferHelper.safeApprove(_lpToken, address(migrator), _amount);
    migrator.migrate(_lpToken, _amount, userLock.unlockDate, msg.sender);
  }
  
  function getNumLocksForToken (address _lpToken) external view returns (uint256) {
    return tokenLocks[_lpToken].length;
  }
  
  function getNumLockedTokens () external view returns (uint256) {
    return lockedTokens.length();
  }
  
  function getLockedTokenAtIndex (uint256 _index) external view returns (address) {
    return lockedTokens.at(_index);
  }
  
  // User functions
  function getUserNumLockedTokens (address _user) external view returns (uint256) {
    UserInfo storage user = users[_user];
    return user.lockedTokens.length();
  }
  
  function getUserLockedTokenAtIndex (address _user, uint256 _index) external view returns (address) {
    UserInfo storage user = users[_user];
    return user.lockedTokens.at(_index);
  }
  
  function getUserNumLocksForToken (address _user, address _lpToken) external view returns (uint256) {
    UserInfo storage user = users[_user];
    return user.locksForToken[_lpToken].length;
  }
  
  function getUserLockForTokenAtIndex (address _user, address _lpToken, uint256 _index) external view 
  returns (uint256, uint256, uint256, uint256, uint256, address) {
    uint256 lockID = users[_user].locksForToken[_lpToken][_index];
    TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
    return (tokenLock.lockDate, tokenLock.amount, tokenLock.initialAmount, tokenLock.unlockDate, tokenLock.lockID, tokenLock.owner);
  }
  
  // Whitelist
  function getWhitelistedUsersLength () external view returns (uint256) {
    return feeWhitelist.length();
  }
  
  function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
    return feeWhitelist.at(_index);
  }
  
  function getUserWhitelistStatus (address _user) external view returns (bool) {
    return feeWhitelist.contains(_user);
  }
}