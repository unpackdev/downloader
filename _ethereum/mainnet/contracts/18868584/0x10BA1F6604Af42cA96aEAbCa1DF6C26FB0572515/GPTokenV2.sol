// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";

contract GPTokenV2 is ERC20, ERC20Burnable, Pausable, Ownable {

    event TimeLock(address indexed account, uint256 amount, uint256 startTime, uint256 releaseMonths);
    event TimeLockUpdate (address indexed account, uint256 valueIndex, uint256 value);
    
    struct LockInfo {
        uint256 amount;    
        uint256 startTime;
        uint256 releaseMonths;
    }
    
    mapping(address => LockInfo) private _lockInfos;

    address[] private _lockedWallets;

    constructor() ERC20("HYPERGRAY COIN", "HGC") 
    {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner 
    {
        _pause();
    }

    function unpause() public onlyOwner 
    {
        _unpause();
    }

    function setLock(address walletAddress, uint256 startTime, uint256 releaseMonths, uint256 amount) 
        public
        onlyOwner 
    {
        require(_lockInfos[walletAddress].amount < 1, "Aleady exist lock info.");
        require(block.timestamp < startTime, "ERC20: Current time is greater than start time.");
        require(releaseMonths > 0, "ERC20: ReleaseMonths is greater than 0.");
        require(amount > 0, "ERC20: Amount is greater than 0.");
        
        _lockInfos[walletAddress] = LockInfo(amount, startTime, releaseMonths);
        _lockedWallets.push(walletAddress);

        emit TimeLock( walletAddress, amount, startTime, releaseMonths ); 
    }

    function setLockReleaseMonths(address walletAddress, uint256 releaseMonths)
        public
        onlyOwner
    {
        require(_lockInfos[walletAddress].amount > 0, "Not exist lock info.");
        require(releaseMonths > 0, "ERC20: ReleaseMonths is greater than 0.");
        _lockInfos[walletAddress].releaseMonths = releaseMonths;

        emit TimeLockUpdate (walletAddress, 3, releaseMonths);
    }

    function setLockStartTime(address walletAddress, uint256 startTime)
        public
        onlyOwner
    {
        require(_lockInfos[walletAddress].amount > 0, "Not exist lock info.");

        _lockInfos[walletAddress].startTime = startTime;

        emit TimeLockUpdate (walletAddress, 2, startTime);
    }

    function setLockAmount(address walletAddress, uint256 amount)
        public
        onlyOwner
    {
        require(_lockInfos[walletAddress].amount > 0, "Not exist lock info.");

        _lockInfos[walletAddress].amount = amount;

        emit TimeLockUpdate (walletAddress, 1, amount);
    }

    function getLockInfo(address walletAddress) 
        public 
        view 
        returns (uint256 lockAmount, uint256 startTime, uint256 releaseMonths, uint256 released) 
    {
        require(_lockInfos[walletAddress].amount > 0, "Not exist lock info.");
        
        uint256 unLockAmount = _getUnLockAmount(walletAddress, block.timestamp);

        return (_lockInfos[walletAddress].amount, _lockInfos[walletAddress].startTime, _lockInfos[walletAddress].releaseMonths, unLockAmount);
    }

    function getLockWallets()
        public
        view
        virtual
        onlyOwner
        returns (address[] memory) 
    {
        return (_lockedWallets);
    }

    function _getUnLockAmount(address walletAddress, uint256 timestamp)
        internal
        view
        returns (uint256 unLockAmount)
    {
        uint256 lockAmount = _lockInfos[walletAddress].amount;
        uint256 lockStartTime = _lockInfos[walletAddress].startTime;
        uint256 releaseMonths = _lockInfos[walletAddress].releaseMonths;

        if (timestamp < lockStartTime) return 0;

        uint256 checkReleasedSecond = timestamp - lockStartTime;
        uint256 checkReleasedMonth = checkReleasedSecond / (86400 * 30);  //per 30day        

        if (releaseMonths <= checkReleasedMonth) {
            return lockAmount;
        } else if (checkReleasedMonth < 1) {
            return 0;
        } else {
            return lockAmount * checkReleasedMonth / releaseMonths;
        }
    }

    function _isLocked(address walletAddress, uint256 amount) 
        internal 
        view 
        returns (bool) 
    {
        if (_lockInfos[walletAddress].amount != 0) {
            uint256 unLockAmount = _getUnLockAmount(walletAddress, block.timestamp);
            return (balanceOf(walletAddress) - (_lockInfos[walletAddress].amount - unLockAmount)) < amount;
        } else {
            return false;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        require( !_isLocked( from, amount ) , "ERC20: Locked balance.");
        super._beforeTokenTransfer(from, to, amount);
    }

}
