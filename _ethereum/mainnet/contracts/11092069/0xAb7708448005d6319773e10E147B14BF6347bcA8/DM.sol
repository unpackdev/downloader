pragma solidity ^0.4.24;

contract owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
     owner = newOwner;   
    }
}


contract DM is owned {
    uint public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint tokens);
    event Approval(address indexed _tokenOwner, address indexed _spender, uint tokens);
    event Burn(address indexed from, uint256 value);
        
    constructor(string tokenName, string tokenSymbol, uint initialSupply) public  {
        totalSupply = initialSupply * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        
        name = tokenName;
        symbol = tokenSymbol;
    }
    
    function _transfer(address _from ,address _to, uint256 _value) internal {
        // require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]); // when adding money, it will not overflow the transaction.
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value); 
         
    }
    
    function transfer(address _to, uint256 _value) public payable returns(bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transfer_from(address _from, address _to, uint256 _value) public   returns(bool success)  {
        require(_value <= allowance[_from][msg.sender]); // It make sure that the caller has enough allowance to spend from this address
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns(bool success) {
        // In this function we'll allow addresses to spend certain amount of money on our behalf
        // Ex: Owing a company and letting your employees use some amount
        allowance[msg.sender][_spender] == _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function mintToken(address _target, uint256 _mintedAmount) onlyOwner public {
        balanceOf[_target] += _mintedAmount;
        totalSupply += _mintedAmount;
        
        emit Transfer(0, owner, _mintedAmount);
        emit Transfer(owner, _target, _mintedAmount);
    }
    
    function burnToken(uint256 _value)  onlyOwner public returns(bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
}