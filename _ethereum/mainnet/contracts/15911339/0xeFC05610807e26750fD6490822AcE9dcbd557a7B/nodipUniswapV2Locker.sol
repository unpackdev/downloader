 // SPDX-License-Identifier: MIT
pragma solidity =0.8.10 >=0.8.10 >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IERC20Metadata.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
}

interface IUniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

contract LiquidLockUniswapV2Locker is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IUniFactory public uniswapFactory;

    address payable devAddress;
    address FlaggedLPHoldingAddress;
    uint256 lockFee;

    struct UserInfo {
        EnumerableSet.AddressSet userLockedTokens; //stores all tokens locked by address
        mapping(address => uint256[]) locksForToken; //maps the ERC20 uni LP to lock id for token
    }

    struct UserFlagInfo {
        EnumerableSet.AddressSet userFlaggedTokens;
    }

    struct TokenLockInfo {  
        address owner;
        uint256 lockDate;
        uint256 amountLocked;
        uint256 initialLockAmount;
        uint256 unlockDate;
        uint256 lockID;
        address tokenAddress;
        bool flagStatus;
        uint256 currentFlaggedAmount;
    }

    mapping(address => UserInfo) private users;
    mapping(address => bool) public flaggedTokens;
    EnumerableSet.AddressSet private whitelistedUsers;
    EnumerableSet.AddressSet private lockedTokens;
    mapping(address => TokenLockInfo[]) public tokenLocks;
    mapping(address => UserFlagInfo) private usersFlaggedTokens;

    event depositLP(address user, address lpToken, uint256 amountLocked, uint256 lockDate, uint256 unlockDate);
    event withdrawLP(address lpToken, uint256 amount);
    event lpIsFlagged(address lpToken);

    constructor(IUniFactory _uniswapFactory) {
        devAddress = payable(msg.sender);
        FlaggedLPHoldingAddress = devAddress;
        uniswapFactory = _uniswapFactory;
        lockFee = 1e18;
    }

    function setDevAddress(address payable _newDevAddress) public onlyOwner {
        devAddress = _newDevAddress;
    }

    function whitelistAccount(address _user, bool _status) public onlyOwner {
        if(_status) {
            whitelistedUsers.add(_user);
        } else {
            whitelistedUsers.remove(_user);
        }
    }

    function lockLPToken(address _lpToken, uint256 _amount, uint256 _unlockDate, address payable _lockUser) external payable{
        require(_unlockDate < 10000000000, 'Invalid unix timestamp'); // prevents errors when timestamp entered in milliseconds
        require(_amount > 0, 'amount must be greater than 0');

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // ensure this pair is a univ2 pair by querying the factory
        IUniswapV2Pair lpair = IUniswapV2Pair(address(_lpToken));
        address factoryPairAddress = uniswapFactory.getPair(lpair.token0(), lpair.token1());
        address tokenAddressOfPair;
        require(factoryPairAddress == address(_lpToken), 'Not a UNIV2 LP token');

        TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount); 

        if(!whitelistedUsers.contains(msg.sender)) {
            uint256 ethFee = lockFee;
            require(msg.value == ethFee, "Incorrect fee amount");
            devAddress.transfer(ethFee);
        }

        if(lpair.token0() == _uniswapV2Router.WETH()) {
            tokenAddressOfPair = lpair.token1();
        }else {
            tokenAddressOfPair = lpair.token0();
        }

        TokenLockInfo memory token_lock;
        token_lock.owner = _lockUser;
        token_lock.lockDate = block.timestamp;
        token_lock.amountLocked = _amount;
        token_lock.unlockDate = _unlockDate;
        token_lock.initialLockAmount = _amount;
        token_lock.lockID = tokenLocks[_lpToken].length;
        token_lock.tokenAddress = tokenAddressOfPair;
        token_lock.flagStatus = false;
        token_lock.currentFlaggedAmount = 0;

        //record pair lock
        tokenLocks[_lpToken].push(token_lock);
        lockedTokens.add(_lpToken);

        //record lock for user
        UserInfo storage user = users[_lockUser];
        user.userLockedTokens.add(_lpToken);
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(token_lock.lockID);

        emit depositLP(msg.sender, _lpToken, token_lock.amountLocked, token_lock.lockDate, token_lock.unlockDate);
    }

    function withdrawLPToken(address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot withdraw nothing");
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLockInfo storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, "Incorrect lock");

        require(userLock.unlockDate < block.timestamp, "Lock time has not elapsed");
        userLock.amountLocked = userLock.amountLocked.sub(_amount);

        if(userLock.amountLocked == 0) {
            uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
            userLocks[_index] = userLocks[userLocks.length-1];
            userLocks.pop();
            if(userLocks.length == 0) {
                users[msg.sender].userLockedTokens.remove(_lpToken);
            }
        }

        TransferHelper.safeTransfer(_lpToken, msg.sender, _amount);
        emit withdrawLP(_lpToken, _amount);
    }

    function flagToken(address _lpToken, uint256 _lockID) public {
        TokenLockInfo storage tokenLock = tokenLocks[_lpToken][_lockID]; //grab correct lock to flag
        address erc20Token = tokenLock.tokenAddress;
        uint256 userBalaceForVoteCredits = IERC20(erc20Token).balanceOf(msg.sender);
        uint256 erc20TokenTotalSupply = IERC20(erc20Token).totalSupply();

        //check that user has not already flagged
        UserFlagInfo storage validateUserFlag = usersFlaggedTokens[msg.sender];
        require(!validateUserFlag.userFlaggedTokens.contains(_lpToken));

        if(userBalaceForVoteCredits > 0) {
            tokenLock.currentFlaggedAmount += userBalaceForVoteCredits;
            UserFlagInfo storage userFlag = usersFlaggedTokens[msg.sender];
            userFlag.userFlaggedTokens.add(_lpToken);
        }

        if(tokenLock.currentFlaggedAmount > erc20TokenTotalSupply / 2) {
            tokenLock.flagStatus = true;
            changeLockOwnerOnFlag(_lpToken, _lockID);
            emit lpIsFlagged(_lpToken);
        } else {
            tokenLock.flagStatus = false;
        }

    }

    function transferLockOwner(address _lpToken, uint256 _index, uint256 _lockID, address payable _newLockOwner) external {
        require(msg.sender != _newLockOwner);
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLockInfo storage  xferedLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && xferedLock.owner == msg.sender); // cannot xfer lock you do not own

        UserInfo storage user = users[_newLockOwner];
        user.userLockedTokens.add(_lpToken);
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(xferedLock.lockID);

        //remove lock from original owner
        uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
        userLocks[_index] = userLocks[userLocks.length-1];
        userLocks.pop();
        if(userLocks.length == 0) {
            users[msg.sender].userLockedTokens.remove(_lpToken);
        }
        xferedLock.owner = _newLockOwner;
    }

    //Relock token on expiry takes LOCKID and INDEX to ensure correct lock is adjusted - no fees on relock
    function relock(address _lpToken, uint256 _index, uint256 _lockID, uint256 _unlockDate) external nonReentrant {
        require(_unlockDate < 10000000000, 'Invalid unix timestamp'); // prevents errors when timestamp entered in milliseconds
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLockInfo storage  userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender); // cannot edit lock you do not own
        require(userLock.unlockDate < _unlockDate); //cannot relock before lock expiry

        uint256 amountLocked = userLock.amountLocked;

        userLock.amountLocked = amountLocked;
        userLock.unlockDate = _unlockDate;
    }

    function extendLock(address _lpToken, uint256 _index, uint256 _lockID, uint256 _unlockDate) external nonReentrant {
        require(_unlockDate < 10000000000, 'Invalid unix timestamp'); // prevents errors when timestamp entered in milliseconds
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLockInfo storage  userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender); // cannot edit lock you do not own
        require(_unlockDate > userLock.unlockDate, "Cannot set lock earlier than previous lock");

        userLock.unlockDate = _unlockDate;
    } 

    function getLPTokenCurrentFlaggedAmount(address _lpToken, uint256 _lockID) public view returns(uint256){
        TokenLockInfo storage tokenLock = tokenLocks[_lpToken][_lockID];
        return tokenLock.currentFlaggedAmount;
    }

    function getERC20TokenTotalSuppy(address _erc20Token) public view returns(uint256) {
        return IERC20(_erc20Token).totalSupply();
    }
    
    function getLPTokenFlagStatus(address _lpToken, uint256 _lockID) public view returns(bool) {
        TokenLockInfo storage tokenLock = tokenLocks[_lpToken][_lockID];
        return tokenLock.flagStatus;
    }

    function changeLockOwnerOnFlag(address _lpToken, uint256 _lockID) internal {
        TokenLockInfo storage lockToForceChange = tokenLocks[_lpToken][_lockID];
        uint256 lockerLPTokenBalance = IERC20(_lpToken).balanceOf(address(this));

        //change lock owner to LP holding address
        UserInfo storage user = users[FlaggedLPHoldingAddress];
        user.userLockedTokens.add(_lpToken);
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(lockToForceChange.lockID);

      
        lockToForceChange.owner = FlaggedLPHoldingAddress;
        TransferHelper.safeTransfer(_lpToken, FlaggedLPHoldingAddress, lockerLPTokenBalance); //moves LP to the holding address for investigation and redistribution 
    }

    function updateLockFee(uint256 _newLockFee) public onlyOwner {
        lockFee = _newLockFee;
    }

    function updateLPHoldingAddress(address _newAddress) public onlyOwner {
        FlaggedLPHoldingAddress = _newAddress;
    }

}



