pragma solidity ^0.4.25;

contract ArthurToken{
    
    string public symbol;
    string public  name;
    uint public decimals;
    uint _value2;
    
	address owner;
	uint public totalSupply;
    mapping(address => uint) balances;

    constructor(uint _initialSupply)public{
        symbol = "KKK";
        name = "King of King Coin";
        decimals = 18;
       
        totalSupply = _initialSupply*10**uint(decimals);
        owner = msg.sender;
        balances[owner] = totalSupply;
        

    }
    function balanceOf(address _someone)public view returns(uint){
    	return balances[_someone];
    }
    function transfer(address _to,uint _value) public returns(bool){
        _value2 = _value *10**(decimals);
        require(_value2 > 0);
        require(balances[owner] >= _value2);
        balances[msg.sender] -= _value2;
        balances[_to] += _value2;
        return true;
    }
}