// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SwapAdmin.sol";

contract SwapTokenLocker is SwapAdmin {
    using SafeMath for uint;

    struct LockInfo {
        uint256 amount;
        uint256 lockTimestamp; // lock time at block.timestamp
        uint256 lockHours;
        uint256 claimedAmount;
        uint256 lastUpdated;
    }
    mapping (address => mapping(address => LockInfo)) public lockData;
    mapping (address => address[]) public claimableTokens;
    
    constructor(address _admin) public SwapAdmin(_admin) {}
    
	function getLockData(address _user, address _tokenAddress) external view returns(uint256, uint256, uint256, uint256, uint256) {
        require(_user != address(0), "User address is invalid");
        require(_tokenAddress != address(0), "Token address is invalid");

        LockInfo storage _lockInfo = lockData[_user][_tokenAddress];
		return (_lockInfo.amount, _lockInfo.lockTimestamp, _lockInfo.lockHours, _lockInfo.claimedAmount, _lockInfo.lastUpdated);
	}

    function getClaimableTokens(address _user) external view returns (address[] memory) {
        require(_user != address(0), "User address is invalid");
        return claimableTokens[_user];
    }

    function sendLockTokenMany(
        address[] calldata _users, 
        address[] calldata _tokenAddresses, 
        uint256[] calldata _amounts, 
        uint256[] calldata _lockTimestamps, 
        uint256[] calldata _lockHours,
        address[] calldata _allTokenAddresses,
        uint256[] calldata _sendAmounts
    ) external onlyAdmin {
        require(_users.length == _amounts.length, "array length not eq");
        require(_users.length == _lockHours.length, "array length not eq");
        require(_users.length == _lockTimestamps.length, "array length not eq");
        require(_users.length == _tokenAddresses.length, "array length not eq");
        require(_allTokenAddresses.length == _sendAmounts.length, "Send token address length and amounts length are not eq");
        for (uint256 i = 0; i < _allTokenAddresses.length; i ++) {
            IERC20(_allTokenAddresses[i]).transferFrom(msg.sender, address(this), _sendAmounts[i]);
        }
        for (uint256 j = 0; j < _users.length; j++) {
            sendLockToken(_users[j], _tokenAddresses[j], _amounts[j], _lockTimestamps[j], _lockHours[j]);
        }
    }

    function sendLockToken(
        address _user, 
        address _tokenAddress, 
        uint256 _amount, 
        uint256 _lockTimestamp, 
        uint256 _lockHours
    ) internal {
        require(_amount > 0, "amount can not zero");
        require(_lockHours > 0, "lock hours need more than zero");
        require(_lockTimestamp > 0, "lock timestamp need more than zero");
        require(_tokenAddress != address(0), "Token address is invalid");
        require(lockData[_user][_tokenAddress].amount == 0, "this address has already locked");
        
        LockInfo memory lockinfo = LockInfo({
            amount: _amount,
            //lockTimestamp: block.timestamp,
            lockTimestamp: _lockTimestamp,
            lockHours: _lockHours,
            lastUpdated: block.timestamp,
            claimedAmount: 0
        });

        lockData[_user][_tokenAddress] = lockinfo;
        claimableTokens[_user].push(_tokenAddress);
    }
    
    function claimToken(uint256 _amount, address _tokenAddress) external returns (uint256) {
        require(_amount > 0, "Invalid parameter amount");
        address _user = msg.sender;

        require(_tokenAddress != address(0), "Token address is invalid");

        LockInfo storage _lockInfo = lockData[_user][_tokenAddress];

        require(_lockInfo.lockTimestamp <= block.timestamp, "Vesting time is not started");
        require(_lockInfo.amount > 0, "No lock token to claim");

        uint256 passhours = block.timestamp.sub(_lockInfo.lockTimestamp).div(1 hours);
        require(passhours > 0, "need wait for one hour at least");
        require((block.timestamp - _lockInfo.lastUpdated) > 1 hours, "You have to wait at least an hour to claim");

        uint256 available = 0;
        if (passhours >= _lockInfo.lockHours) {
            available = _lockInfo.amount;
        } else {
            available = _lockInfo.amount.div(_lockInfo.lockHours).mul(passhours);
        }
        available = available.sub(_lockInfo.claimedAmount);
        require(available > 0, "not available claim");
        uint256 claim = _amount;
        if (_amount > available) { // claim as much as possible
            claim = available;
        }

        _lockInfo.claimedAmount = _lockInfo.claimedAmount.add(claim);

        IERC20(_tokenAddress).transfer(_user, claim);
        _lockInfo.lastUpdated = block.timestamp;

        return claim;
    }
}

