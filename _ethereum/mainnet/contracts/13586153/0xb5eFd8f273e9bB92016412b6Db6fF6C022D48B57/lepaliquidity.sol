/*
Contract Security Audited by Certik : https://www.certik.org/projects/lepasa
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "./Pausable.sol";
import "./Ownable.sol";

interface TransferLepa {
    function transfer(address recipient,uint256 amount) external returns (bool);
}

contract LepaLiquidityBucket is Pausable,Ownable {
    TransferLepa private _lepaToken;
    mapping( address => uint256) public userAllocation;
    uint256 public totalMembers;    
    uint256 public allocatedSum;
    
    event GrantAllocationEvent(address allcationAdd, uint256 amount);    

    constructor(TransferLepa tokenAddress)  {
        require(address(tokenAddress) != address(0), "Token Address cannot be address 0");
        _lepaToken = tokenAddress;
        totalMembers = 0;
        allocatedSum = 0;
    }

    function GrantAllocation(address[] calldata _allocationAdd, uint256[] calldata _amount) external whenNotPaused onlyOwner{
      require(_allocationAdd.length == _amount.length);
      
      for (uint256 i = 0; i < _allocationAdd.length; ++i) {
            _GrantAllocation(_allocationAdd[i],_amount[i]);
        }
    }

    function _GrantAllocation(address allocationAdd, uint256 amount) internal {
        require(allocationAdd != address(0), "Invalid allocation address");
        require(amount > 0, "Invalid allocation amount");

        if(userAllocation[allocationAdd] == 0) {
            totalMembers++;
        }
        allocatedSum = allocatedSum  + amount;
        userAllocation[allocationAdd] += amount;
        emit GrantAllocationEvent(allocationAdd, amount);
        require(_lepaToken.transfer(allocationAdd, amount), "Token transfer failed!");
    }

    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }
}