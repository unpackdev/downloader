/*
  Timelock.sol 
  - This contract safeguards its assets through a timelock
  - To withdraw assets, the contract owner must initiate the unlock
  - The unlock period amounts to 1 week after the unlock is initiated
  - After this week, the contract owner can withdraw assets at their discretion 
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {

    function transfer(address recipient, uint amount) external returns (bool);

}

contract Timelock {

    address public constant owner = 0x60713fb108E323D83b1fbd7B3C95984f6F5eCD02;
    uint256 public oneWeek = 60 * 15; // 15 min
    uint256 public unlockTime;

    /*
      @require Requires the unlock time have not been set and msg.sender to be equal to contract owner
    */
    function unlock() public {

        require(msg.sender == owner);
        require(unlockTime == 0);
        unlockTime = block.timestamp + oneWeek;

    }

    /*
      @require Requires the unlock time to have passed, unlock time to be set, and msg.sender to be equal to contract owner
      @param token The ERC20 token contract being transfered out of the contract
      @param amount The amount of said ERC20 token
    */
    function withdraw(address token, uint256 amount) public {

        require(msg.sender == owner);
        require(unlockTime != 0);
        require(unlockTime <= block.timestamp);
        
        IERC20(token).transfer(msg.sender, amount);

    }

}
