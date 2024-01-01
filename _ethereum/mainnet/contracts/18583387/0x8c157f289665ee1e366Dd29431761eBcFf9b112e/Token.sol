// SPDX-License-Identifier: MIT


pragma solidity ^0.8.22;

/**
 * Abstract contract to easily change things when deploying new projects. Saves me having to find it everywhere.
 */
abstract contract Project {
    address public marketingWallet = 0x51Ed86C045C9d03Ec458fd64ffC47E17e9c4a3c0;
    address public devWallet = 0x51Ed86C045C9d03Ec458fd64ffC47E17e9c4a3c0;

    string constant _name = "Bitreserve";
    string constant _symbol = "BRV";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 5 * 10**9 * 10**_decimals;

    uint256 public _maxTxAmount = (_totalSupply * 10) / 1000; // (_totalSupply * 10) / 1000 [this equals 1%]
    uint256 public _maxWalletToken = (_totalSupply * 10) / 1000; //

    uint256 public buyFee             = 5;
    uint256 public buyTotalFee        = buyFee;

    uint256 public swapLpFee          = 2;
    uint256 public swapMarketing      = 1;
    uint256 public swapTreasuryFee    = 2;
    uint256 public swapTotalFee       = swapMarketing + swapLpFee + swapTreasuryFee;

    uint256 public transFee           = 5;

    uint256 public feeDenominator     = 100;

}

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 5000000000 * 10 ** 18;
    string public name = "bitreserve";
    string public symbol = "BRV";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) view  public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}