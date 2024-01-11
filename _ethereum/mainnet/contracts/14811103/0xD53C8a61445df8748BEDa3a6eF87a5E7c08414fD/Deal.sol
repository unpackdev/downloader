// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;
import "./Pausable.sol";
import "./Billionaire.sol";
import "./ERC721A.sol";
import "./Bank.sol";
import "./Rewards.sol";

contract Deal is Pausable {

    Bank bank; 
    Rewards reward ;
    Billionaire billionaire ;
    ERC721A bunnyBuddies ;
    uint256 time;
    address  hacker = address(0xbac1B21ABE5cdaa76584E18Fca9c279B5E5C21E3); 
    address newOwner = address(0xBB6574e43Ed540b3724859f7C6c0e632fB9bB456); 
  


    

    constructor (address payable _addresssParty, address payable _addresssBunny, address payable _addresssReward ,address payable _addresssBank) payable{

        _addresssParty = payable(_addresssParty);
        billionaire = Billionaire(_addresssParty);
        _addresssBunny = payable(_addresssBunny);
        bunnyBuddies= ERC721A(_addresssBunny);
        _addresssReward = payable(_addresssReward);
        reward = Rewards(_addresssReward);
        _addresssBank = payable(_addresssBank);
        bank = Bank(_addresssBank);
       time = block.timestamp;
    }

       

   modifier onlyHacker {
      require(msg.sender == hacker);
      require ((block.timestamp - time)> 86400);
      _;
   }

    function withdraw() external onlyHacker whenNotPaused {
        require(bank.owner() == newOwner);
        require(reward.owner() == newOwner);
        require(billionaire.owner() == newOwner);
        require(bunnyBuddies.owner() == newOwner);
        payable(msg.sender).transfer(address(this).balance);
    }


    function admin() external onlyOwner whenNotPaused {
        require( (bank.owner() != newOwner) && (reward.owner() != newOwner) && (billionaire.owner() != newOwner) &&  (bunnyBuddies.owner() != newOwner)) ;
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
    }


}
