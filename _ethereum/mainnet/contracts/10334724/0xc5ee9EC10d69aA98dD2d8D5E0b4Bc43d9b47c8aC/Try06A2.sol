// "SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.6.9;

contract Try06A2
{
    using SafeMath for uint256;
    
    address admin;

    //@ Token attributes
    string public constant symbol = "TRY6A2";
    string public constant name = "Try06A2 Token";
    uint8 public constant decimals = 16;
    uint256 totalSupply = 4000000000 * 10 ** uint256(decimals);
  
    
    //@ Event logging
    event Transfer (address payable indexed _to,uint256 indexed _value);
    event Approve (address payable indexed _from, address payable indexed _to, uint256 indexed _value);
    event TransferFrom (address payable indexed _owner,address payable indexed _from, address payable indexed _to, uint256 _amount);

    //@ Maps: ethereum address to number of tokens
    mapping (address => uint256) public balances;
    
    //@ Owner can allows some other ethereum address to spend the allocated amount of tokens.
    mapping (address => mapping (address => uint256)) public allowance;
    
    //@ Constructor / Setup 
    constructor () public 
    {
        admin = msg.sender;
        balances[admin] = totalSupply;
  
    }
    
    // Checks value entered is valid or not.
    modifier isValidAmount (uint256 _value)
    {
        require (_value > 0, "Invalid amount!");
        _;
    }
    
     //@ Usual transfer function transfer tokens from one accont to another.
    function transfer (address payable _to, uint256 _value) public 
    isValidAmount (_value)
    returns (bool success)
    {
        require (balances[msg.sender] > _value, "Insuffcient balance");
        
        _transfer (msg.sender, _to, _value);    
       
        emit Transfer (_to, _value);
       
        return true;
    }
    
    //@ This fuction give approvement for allowance of a certain value to be spend by a third party address.
    //@ Like a wallet put some value in it and number of token allocated in it is used by address to it the tokens are allocated.
    function approve (address payable _spender, uint256 _value) public 
    isValidAmount (_value)
    returns (bool success)
    {
        require (_spender != address(0), "Address not Exist");
        require (_value > 0, "Invalid amount");
        require (balances[msg.sender] > 0, "Insuffcient balance");
        
        allowance[_spender][msg.sender] = _value;
        
        emit Approve (msg.sender, _spender, _value);
        
        return true;
    }
    
    //@ This function is specific to allowance mapping only the one's allocated with certain amount of token 
    //@ can access this function
    function transferFrom (address payable _from, address payable _to, uint256 _amount) public 
    isValidAmount (_amount)
    returns (bool success)
    {
        require (allowance[msg.sender][_from] >= _amount);
        require (balances[_from] > _amount, "The owner has Insufficent balance");
        
        allowance[msg.sender][_from] -= _amount;
        balances[_from] -=_amount;
        balances[_to] += _amount;
        
        emit TransferFrom (_from, msg.sender, _to, _amount);
        
        return true;
    }
    function getTotalSupply() public view returns (uint256) {
    return totalSupply;
    }

    function getMyBalance() public view returns (uint) {
    return balances[msg.sender];
    }
    function getBalanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
    }

    //@ Internal function
    function _transfer (address _from, address _to, uint256 _value) internal isValidAmount (_value){
        
        require (_to != address(0), "Address not Exist");
        require (balances[_from] > _value, "Insufficent balance");
        
        balances[_to] += _value;
        balances[_from] -= _value;
    }
}

library SafeMath {
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
    }

function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
    }

function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
    }

function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
    }
}