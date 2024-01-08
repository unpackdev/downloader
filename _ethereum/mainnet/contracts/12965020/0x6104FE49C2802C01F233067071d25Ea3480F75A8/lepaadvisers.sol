// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface TransferLepa {
    function transfer(address recipient,uint256 amount) external;
}

contract LepaAdvisersBucket is Pausable,Ownable {
    using SafeMath for uint256;
    TransferLepa private _lepaToken;

    struct Bucket {
        uint256 allocation;
        uint256 claimed;
    }

    mapping( address => Bucket) public users;

    uint256 public maxLimit =  5 * (10**6) * 10**18;
    uint256 public vestingDays = 365;
    uint256 public totalMembers;    
    uint256 public allocatedSum;
    uint256 public contractCreation;

    event GrantAllocationEvent(address allcationAdd, uint256 amount);    
    event ClaimBalanceEvent(address addr, uint256 balance);

    constructor(TransferLepa tokenAddress)  {
        _lepaToken = tokenAddress;
        totalMembers = 0;
        allocatedSum = 0;
        contractCreation = 0;
    }

    function setCreationTime(uint256 epochtime) public onlyOwner {
        contractCreation = epochtime;
    }
    
    function setTokenAddress(TransferLepa tokenAddress) public onlyOwner {
        _lepaToken = tokenAddress;
    }

    function GrantAllocation(address allocationAdd, uint256 amount) public onlyOwner whenNotPaused {
        require(allocationAdd != address(0), "Invalid allocation address");
        require(amount > 0, "Invalid allocation amount");
        require(amount > users[allocationAdd].allocation, "Amount cannot be less then already allocating amount");
        require(allocatedSum.sub(users[allocationAdd].allocation).add(amount) <= maxLimit, "Limit exceed");

        if(users[allocationAdd].allocation == 0) {                        
            totalMembers = totalMembers.add(1);
        }
        allocatedSum = allocatedSum.sub(users[allocationAdd].allocation).add(amount);
        users[allocationAdd].allocation = amount;        
        emit GrantAllocationEvent(allocationAdd, amount);        
    }

    function GetClaimableBalance(address userAddr) public view returns (uint256) {
        require(contractCreation > 0, "Vesting not initialzed");
        uint256 claimableBal = 0;
        Bucket memory userBucket = users[userAddr];  
        uint256 lockingTimestamp = contractCreation.add(31536000); // 1 Year locking period 365 * 86400 (Seconds)
        require(block.timestamp > lockingTimestamp, "Reserved for 1 Year");
        require(userBucket.allocation != 0, "Address is not registered");                

        uint256 vestingAmount = CalculateVestingAmount(userBucket.allocation, vestingDays);
        claimableBal = vestingAmount.mul(block.timestamp - lockingTimestamp);

        if(claimableBal > userBucket.allocation){
            claimableBal = userBucket.allocation;
        }
        return claimableBal.sub(userBucket.claimed);

    }

    function ProcessClaim() public whenNotPaused {
        uint256 claimableBalance = GetClaimableBalance(_msgSender());
        require(claimableBalance > 0, "Claim amount invalid.");
        
        users[_msgSender()].claimed = users[_msgSender()].claimed.add(claimableBalance);
        _lepaToken.transfer(_msgSender(), claimableBalance);
        emit ClaimBalanceEvent(_msgSender(), claimableBalance);
    }

    function CalculateVestingAmount(uint256 amount, uint256 vdays) private pure returns (uint256) {        
        return amount.div(GetDaysTimstamp(vdays));
    }

    function GetDaysTimstamp(uint256 vdays) private pure returns (uint256) {        
        return vdays.mul(86400); // 1 day = 86400 seconds        
    }
    
    /* Dont accept eth  */
    receive() external payable {
        revert("The contract does not accept direct payment.");
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }
}