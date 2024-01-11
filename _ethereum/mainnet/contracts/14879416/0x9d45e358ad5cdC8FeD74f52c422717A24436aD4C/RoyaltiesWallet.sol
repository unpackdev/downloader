// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract RoyaltiesWallet is PaymentSplitter, Ownable {
    
    string public name;
    constructor (
        string memory _name,
        address[] memory _payees,
        uint[] memory _shares
        ) 
        PaymentSplitter(_payees, _shares) payable {
            name = _name;
        }
        
    function totalBalance() public view returns(uint) {
        return address(this).balance;
    }
        
    function totalReceived() public view returns(uint) {
        return totalBalance() + totalReleased();
    }
    
    function balanceOf(address _account) public view returns(uint) {
        return totalReceived() * shares(_account) / totalShares() - released(_account);
    }
    
    function release(address payable account) public override onlyOwner {
        super.release(account);
    }
    
    function withdraw() public {
        require(balanceOf(msg.sender) > 0, "No funds to withdraw");
        super.release(payable(msg.sender));
    }
    
}