pragma solidity ^0.7.0;
 
contract ZeroValueToken {
    string public name = "Zero Value Token";
    string public symbol = "0VT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 42000000 * 1e18;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    constructor () {
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function balanceOf(address owner) 
    public
    view
    returns (uint256)
    {
        return _balances[owner];
    }
    
    function transfer(address to, uint256 value)
    public
    returns (bool)
    {
        require(to != address(0));
        require(value <= _balances[msg.sender]);
        require(_balances[to] + value >= _balances[to]);
        _balances[msg.sender] = _balances[msg.sender] - value;
        _balances[to] = _balances[to] + value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
    public
    returns (bool)
    {
        require(to != address(0));
        require(value <= _balances[from]);
        require(_balances[to] + value >= _balances[to]);
        require(value <= _allowed[from][msg.sender]);
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;
        _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value)
    public
    returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
   
    function allowance(address owner, address spender)
    public
    view
    returns (uint256)
    {
        return _allowed[owner][spender];
    }
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}