pragma solidity ^0.6.2;

interface ERC20Interface {
    //Optional
    // function name() external view returns (string memory);
    // function symbol() external view returns (string memory);
    // function decimals() external view returns (uint8);

    //Required
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);

    //Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20Interface {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    uint internal _totalSupply;
    address internal _founder;

    mapping(address => uint) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowed;

    enum TokenModel { standard, ito, mint }
    TokenModel internal _model = TokenModel.standard;

    //Events
    //event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor (string memory name, string memory symbol, uint initialSupply, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _founder = msg.sender;
        _totalSupply = initialSupply;
        _balances[_founder] = initialSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256){
        return _balances[_owner];
    }

    function tokenModel() public view returns (string memory) {
        if (_model == TokenModel.mint) {
            return "mint";
        } else if (_model == TokenModel.ito){
            return "ito";
        } else {
            return "standard";
        }
    }

    function transfer(address _to, uint256 _value) public override virtual returns (bool){
        require(_value <= _balances[msg.sender]);
        require(_to != address(0));

        _balances[msg.sender] = _balances[msg.sender] - _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override virtual returns (bool){
        require(_value <= _balances[_from]);
        require(_value <= _allowed[_from][msg.sender]);
        require(_to != address(0));

        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public override returns (bool){
        require(_value > 0);
        require(_spender != address(0));
        require(_balances[msg.sender] >= _value);

        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256){
        return _allowed[_owner][_spender];
    }

    function increaseAllowance(address spender, uint256 increaseValue) public returns(bool) {
        require(spender != address(0));
        require(_balances[msg.sender] >= _allowed[msg.sender][spender]+increaseValue);

        _allowed[msg.sender][spender] += increaseValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 decreaseValue) public returns(bool) {
        require(spender != address(0));
        if(_allowed[msg.sender][spender] >= decreaseValue) {
            _allowed[msg.sender][spender] -= decreaseValue;
        } else {
            _allowed[msg.sender][spender] = 0;
        }
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0));
        require(amount <= _balances[account]);

        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender]);
        _allowed[account][msg.sender] -= amount;
        _burn(account, amount);
    }
}

contract TokenFactory {
    address private _admin;
    address[] public tokens;

    modifier restricted_admin() {
        require(msg.sender == _admin);
        _;
    }

    constructor () public{
        _admin = msg.sender;
    }

    function setAdmin(address newAdmin) public restricted_admin{
        _admin = newAdmin;
    }

    function createToken(string memory name, string memory symbol, uint initialSupply, uint8 decimals) public returns(address){
        //set founder to creator
        address newToken = address(new Token(name, symbol, initialSupply, decimals));
        tokens.push(newToken);
        return newToken;
    }

    function getTokens() public view returns (address[] memory){
        return tokens;
    }
}