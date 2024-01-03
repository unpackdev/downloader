pragma solidity ^0.5.0;

contract Token {
    string  public name = "Repository.Finance";
    string  public symbol = "RSF";
    uint256 public totalSupply = 100000000000000000000000; // 100 thousand tokens
    uint8   public decimals = 18;
    uint public burnRate = 20; //5%
    address public owner;

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

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        uint burned;
        if(msg.sender != owner)
        {
          burned = _value / burnRate;
        } else
        {
          burned = 0;
        }
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += (_value - burned);

        emit Transfer(msg.sender, 0x0000000000000000000000000000000000000000, burned);
        emit Transfer(msg.sender, _to, (_value - burned));
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        uint burned;
        if(_from != owner)
        {
          burned = _value / burnRate;
        } else
        {
          burned = 0;
        }
        balanceOf[_from] -= _value;
        balanceOf[_to] += (_value - burned);
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, 0x0000000000000000000000000000000000000000, burned);
        emit Transfer(_from, _to, (_value - burned));
        return true;
    }
}