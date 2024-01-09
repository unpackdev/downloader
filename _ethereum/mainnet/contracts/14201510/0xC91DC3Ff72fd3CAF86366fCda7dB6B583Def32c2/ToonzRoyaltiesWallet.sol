// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract ToonzRoyaltiesWallet is PaymentSplitter, Ownable {
    
    string public name = "Toonz Royalties Wallet";
    uint[] private _shares = [60, 20, 20];
    address[] private _payees = [
        0xb047464bD7C66d0553FE7Ead00b8aB9a77fd0097,
        0xd9fA4Ab0143A7027AEFE148707F5913cBf3aA5d2,
        0x3aB4085EA8255c22f7670Ad2a278BfA5bF29642F
    ];

    constructor () PaymentSplitter(_payees, _shares) payable {}
        
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