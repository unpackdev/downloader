pragma solidity >=0.5.0;

contract Token {
    string  public name = "Space-iz Token";
    string  public symbol = "SPIZ";
    string  public standard = "SPIZ Token v1.0";
    uint256 public totalSupply = 300000000;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor () public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer (address _to, uint256 _value) public returns (bool success) {
        // throw exception if account doesn't have enough balance
        require(balanceOf[msg.sender] >= _value); // msg.sender is the owner, we'll send it when we'll call this function
        // transfer the balance
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        // trasfer trigger event
        emit Transfer (msg.sender, _to, _value);
        // returns a bool
        return true;

    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}