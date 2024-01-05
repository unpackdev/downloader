/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./TokenAllocation.sol";
import "./IERC20Timelock.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

contract ERC20Timelock is IERC20Timelock, Context, ReentrancyGuard{
    using SafeMath for uint;

    address public Owner;
    address public TokenOwner;

    mapping(string => TokenAllocation) public Allocations;
    string[] public AllocationIndexer;

    constructor(address owner, address tokenOwner) public{
        Owner = owner;
        TokenOwner = tokenOwner;
    }

    //Returns number of existing Allocations so that frontend can loop through them -> 
    //(call this for loop numbers(number of allocations) -> loop through AllocationIndexer to get keys 
    //-> get Allocation from mapping with given key)
    function AllocationLength() override public view returns (uint256) {
        return AllocationIndexer.length;
    }

    function AddAllocation(string memory name, uint256 amount, uint256 releaseDate, bool isInterval, uint256 percentageOfRelease, uint256 intervalOfRelease, address token) OnlyOwner() override external{
        require(IERC20(token).allowance(_msgSender(), address(this)) >= amount , "Transfer of token has not been approved");
        Allocations[name] = TokenAllocation(
            {
                Name:name,
                Amount:amount,
                RemainingAmount:amount,
                ReleaseDate:releaseDate,
                IsInterval:isInterval,
                PercentageOfRelease:percentageOfRelease,
                IntervalOfRelease:intervalOfRelease,
                Exists:true,
                Token:token
            }
        );
        AllocationIndexer.push(name);
        IERC20(token).transferFrom(_msgSender(), address(this), amount);
    }

    function WithdrawFromAllocation(string memory name) nonReentrant() RequireTokenOwner() override external{
        TokenAllocation memory allocation = Allocations[name];
        require(allocation.Exists, "Allocation with that name does not exist!");
        if(!allocation.IsInterval) //regular locked
        {
            require(allocation.ReleaseDate < block.timestamp, "Allocation is not unlocked yet!");
            require(allocation.RemainingAmount > 0, "Insufficient allocation remaining!");
            Allocations[name].RemainingAmount = allocation.RemainingAmount.sub(allocation.Amount);
            IERC20(allocation.Token).transfer(TokenOwner, allocation.Amount);
        }else
        {
            require(allocation.ReleaseDate < block.timestamp, "Token release has not started yet!");
            require(allocation.RemainingAmount > 0, "Insufficient allocation remaining!");
            uint256 claimed = allocation.Amount.sub(allocation.RemainingAmount);
            uint256 elapsed = block.timestamp.sub(allocation.ReleaseDate);
            uint256 releaseTimes = elapsed.div(allocation.IntervalOfRelease * 1 days);
            require(releaseTimes > 0, "No interval available!");
            uint256 toRelease = allocation.Amount.div(100).mul(allocation.PercentageOfRelease).mul(releaseTimes).sub(claimed);
            Allocations[name].RemainingAmount = allocation.RemainingAmount.sub(toRelease);
            IERC20(allocation.Token).transfer(TokenOwner, toRelease);
        }
    }

    modifier RequireTokenOwner(){
        require(TokenOwner == _msgSender(), "Caller is not the token owner");
        _;
    }

    modifier OnlyOwner(){
        require(Owner == _msgSender(), "Caller is not the owner");
        _;
    }
}