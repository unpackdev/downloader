// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Unchecked.sol";


contract FameDistributor is Ownable {

    using SafeERC20 for IERC20;
    
    // EVENTS
    event Claim(address indexed user, uint256 amount);
    event LogShares(address indexed user, uint256 shares);
   
    // ERROR
    error SetupError();
    error Expired();
    error AlreadyLogged();
    error NotLogged();
    error NotYet();
    error NoShares();
    error ZeroBalance();

    address public token;
    uint public lastRewardTime;
    uint public startTime;
    uint public totalShares;
    uint public initialRelease;
    uint public distributePeriod;
    uint public tokenPerSec;
    uint public accTokenPerShare;
    uint constant public ACC_PRECISION = 1e18;
    bool public isDeposited;

    mapping(address => UserInfo) public userInfos;

    struct UserInfo {
        uint shares;
        uint vestingDebt;
    }
    
    modifier deposited() {
        if(!isDeposited) revert ZeroBalance();
        _;
    }

    constructor(
        address _token, 
        uint _startTime, 
        uint _amount, 
        uint _initialRelease, 
        uint _distributePeriod
    ) 
        Ownable(msg.sender) 
    {
        if(_startTime < block.timestamp) revert SetupError();
        lastRewardTime = _startTime;
        startTime = _startTime;
        token = _token;
        initialRelease = _initialRelease;
        distributePeriod = _distributePeriod;
        tokenPerSec = _amount / distributePeriod;
    }


    function depositTokens() onlyOwner external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), initialRelease + tokenPerSec * distributePeriod);
        isDeposited = true;
    }
    
    function logShares(address[] memory users, uint[] memory shares) external onlyOwner {
        if(startTime < block.timestamp) revert Expired();
        
        for(uint i = 0; i < users.length; i = uncheckedInc(i)) {
            _logSingleShare(users[i], shares[i]);
        }
    }

    function _logSingleShare(address user, uint shares) internal {
        if(userInfos[user].shares != 0) revert AlreadyLogged();
        totalShares += shares;
        userInfos[user].shares = shares;

    }


    function update() public deposited {
        _update();
    }

    function _update() internal {
        // before start time, no update
        if(lastRewardTime >= block.timestamp) return;

        // should not happen, contract will be useless if lastRewardTime is before and no shares were logged.
        if(totalShares == 0) revert NotLogged();
        
        uint256 multiplier = _getMultiplier(lastRewardTime, block.timestamp);
        if(multiplier > 0) {
            if(accTokenPerShare == 0 && totalShares != 0) {
                accTokenPerShare = initialRelease * ACC_PRECISION / totalShares;
            }

            uint256 pending = multiplier * tokenPerSec;
            if(pending > 0) {
                accTokenPerShare = accTokenPerShare + (pending * ACC_PRECISION / totalShares);
            }
            lastRewardTime = block.timestamp;
        }
    }


    function _getMultiplier(uint _lastRewardTime, uint _now) internal view returns (uint) {
        // if not started 
        if(_lastRewardTime >= _now) return 0;
        uint endTime = startTime + distributePeriod;
        // if started but not ended
        if(_now >= _lastRewardTime && endTime > _now) return  _now - _lastRewardTime;
        // if ended 
        if(_now >= endTime && endTime > _lastRewardTime) return endTime - _lastRewardTime;
    }
    

    function pendingClaim(address _user) external view returns (uint){
        UserInfo storage info = userInfos[_user];
        uint256 _accTokenPerShare = accTokenPerShare;
        if(accTokenPerShare == 0 && totalShares != 0) {
            _accTokenPerShare = initialRelease * ACC_PRECISION / totalShares;
        }
            
        if (block.timestamp > lastRewardTime && totalShares != 0) {
            uint256 multiplier = _getMultiplier(lastRewardTime, block.timestamp);
            uint256 pending = multiplier * tokenPerSec;
            _accTokenPerShare = _accTokenPerShare + (pending * ACC_PRECISION / totalShares);
        }
        return ((_accTokenPerShare * info.shares) - info.vestingDebt) / ACC_PRECISION;
    }
    

    function claim() external deposited {
        if(block.timestamp < startTime) revert NotYet();
        if(userInfos[msg.sender].shares == 0) revert NoShares();

        _update();
        UserInfo storage info = userInfos[msg.sender];
        uint pending = (accTokenPerShare * info.shares - info.vestingDebt) / ACC_PRECISION;
        info.vestingDebt = accTokenPerShare * info.shares;

        IERC20(token).safeTransfer(msg.sender, pending);
        emit Claim(msg.sender, pending);
    }
}