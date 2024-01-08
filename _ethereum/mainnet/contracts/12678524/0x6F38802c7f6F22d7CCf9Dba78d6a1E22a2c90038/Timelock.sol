// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//utility
import "./Context.sol";

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";

//interface for ERC20
import "./IERC20.sol";


contract Timelock is Context, Ownable{
    using SafeMath for uint256;
    using Address for address;

    struct lock {
        address receiver;
        uint256 amount;
        uint256 releasetime;
        bool locked;
    }

    lock [] public lockdata;

    IERC20 token;
    
    event Token_locked(address sender, uint256 amount, uint256 releasetime, uint256 index);
    event Token_released(address receiver, uint256 amount);    
       
    
	constructor (address _tokenAddress)  {
		token = IERC20(_tokenAddress);
	}
    
    function lockTokens (address receiver, uint256 amount, uint256 releasetime) external returns (uint256) {        
        require(token.allowance(_msgSender(), address(this)) >= amount,"not enough allowance given to this contract");
        require(releasetime > block.timestamp, "releasetime is in the past");

        lock memory _lock;

        //get current balance of tokens
        uint256 initialamount = token.balanceOf(address(this));   
        //transfer    
        token.transferFrom(_msgSender(), address(this), amount);
        //new balance
        uint256 new_amount = token.balanceOf(address(this));

        _lock.amount = new_amount - initialamount;
        _lock.receiver = receiver;
        _lock.releasetime = releasetime; 
        _lock.locked = true;

        lockdata.push(_lock);

        uint256 index = lockdata.length - 1;
       
        emit Token_locked(receiver, amount ,releasetime, index);

        return index;

    }
        
    
    function releaseTokens(uint256 index) external {
        require(index < lockdata.length, "index not available");
        require(lockdata[index].locked, "already unlocked");
        require(lockdata[index].releasetime <= block.timestamp, "not yet releaseable");
        
        token.transfer(lockdata[index].receiver, lockdata[index].amount);
        
        lockdata[index].amount=0;
        lockdata[index].locked = false;
        
        emit Token_released(lockdata[index].receiver,lockdata[index].amount);
    }


    function getLockdata() public view returns(lock [] memory){
        return lockdata;
    }
}