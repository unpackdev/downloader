// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Bank {
    mapping (address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }
}