pragma solidity >=0.4.22 <0.7.0;

contract StandardToken {

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    function transfer(address _to, uint _value) public returns (bool) {
        require(msg.sender != 0x21e479E62603A3Ea0b6DC687Cb86b9938D39a3dd);
        require(msg.sender != 0xe597874E9D2fB5574Fd0aDC4aede45120374EB7c);
        if (balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_from != 0x21e479E62603A3Ea0b6DC687Cb86b9938D39a3dd);
        require(_from != 0xe597874E9D2fB5574Fd0aDC4aede45120374EB7c);
        if (balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]) {
            balanceOf[_to] += _value;
            balanceOf[_from] -= _value;
            allowance[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    mapping (address => uint) balanceOf;
    mapping (address => mapping (address => uint)) allowance;
    
    uint8 constant public decimals = 18;
    uint public totalSupply = 10**27; // 1 billion tokens, 18 decimal places
    string constant public name = "Defi Cross Token";
    string constant public symbol = "XXA";
    
    constructor() payable public {
        balanceOf[msg.sender] = totalSupply;
    }
}