// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


//M&Ms your favorite childhood candy in a memecoin. More novelties coming soon....

//ERC Token standard #20 interface
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint balance);
    function allowance(address owner, address spender) external view returns (uint remaining);
    function transfer(address receipient, uint amount) external returns (bool succss);
    function approve(address spender, uint amount) external returns (bool success);
    function transferFrom(address sender, address receipient, uint amount) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed sender, address indexed spender, uint value);
}

contract Candy is ERC20Interface{
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() {
        symbol = "MMS";
        name = "M&M Coin";
        decimals = 18;
        totalSupply = 50_000_000_000_000_000_000_000_000_000;
        balances[0x2bEAB666CC67fDf9b8da9D376dc367Fa1B9D912A] = totalSupply;
        emit Transfer(address(0), 0x2bEAB666CC67fDf9b8da9D376dc367Fa1B9D912A, totalSupply);
    }

    function TotalSupply() public view returns(uint) {
        return totalSupply - balances[address(0)];
    }

    function balanceOf(address account) public view returns (uint balance) {
        return balances[account];
    }

    function transfer(address recipient, uint amount) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns (bool success) {
        balances[sender] = balances[sender] - amount;
        allowed[sender][msg.sender] = allowed[sender][msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowed[owner][spender];
    }
}