pragma solidity 0.4.19;

contract RegularToken {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
    function transfer(address _to, uint256 _value)public returns (bool){
		if (_value <= 0) revert(); 
        if (balances[msg.sender] < _value) revert();
        if (balances[_to] + _value < balances[_to]) revert();
        balances[msg.sender] = balances[msg.sender]- _value;
        balances[_to] = balances[_to] + _value;
        Transfer(msg.sender, _to, _value);
		return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
		if (_value <= 0) revert(); 
        if (balances[_from] < _value) revert(); 
        if (balances[_to] + _value < balances[_to]) revert();
        if (_value > allowed[_from][msg.sender]) revert(); 
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)public returns (bool) {
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}

contract JOYI is RegularToken {

    uint256 constant public totalSupply = 1*10**26;
    uint8 constant public decimals = 18;
    string constant public name = "JOYI";
    string constant public symbol = "JOYI";
	
    function JOYI()public {
        balances[msg.sender] = totalSupply;
        Transfer(address(0), msg.sender, totalSupply);
    }
}