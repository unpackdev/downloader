// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

contract HARAMBE {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 420696969696942 * 10 ** 18;
    string public name = "HARAMBE";
    string public symbol = "HMB";
    uint public decimals = 18;
    uint public feePercentage = 3;  // Fee percentage to be deducted 0.3%
    address public owner;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        uint fee = (value * feePercentage) / 1000;
        uint amountAfterFee = value - fee;

        balances[to] += amountAfterFee;
        balances[msg.sender] -= value;
        balances[owner] += fee;

        emit Transfer(msg.sender, to, amountAfterFee);
        emit Transfer(msg.sender, owner, fee);

        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');

        uint fee = (value * feePercentage) / 1000;
        uint amountAfterFee = value - fee;

        balances[to] += amountAfterFee;
        balances[from] -= value;
        balances[owner] += fee;

        emit Transfer(from, to, amountAfterFee);
        emit Transfer(from, owner, fee); 

        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}