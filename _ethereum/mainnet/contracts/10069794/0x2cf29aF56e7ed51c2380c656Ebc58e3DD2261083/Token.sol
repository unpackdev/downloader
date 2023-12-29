pragma solidity ^0.5.16;

contract Context {
    constructor () internal { }
    
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


pragma solidity ^0.5.16;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.5.16;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}


pragma solidity ^0.5.16;

contract Token is Context, IERC20 {
    using SafeMath for uint256;
    
    string private _name = 'UBIToken';
    string private _symbol = 'UBI';
    uint8 private _decimals = 2;    
    uint256 private _totalSupply;
    uint256 private _airdropAmount = 8888888; // 88888.88 tokens each address
    
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _initialized; // airdrop initializing
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor () public {
        _initialized[msg.sender] = true;
        _balances[msg.sender] = _airdropAmount;
        _totalSupply = _balances[msg.sender];
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return getBalance(account);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        initialize(msg.sender);
        initialize(recipient);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        initialize(msg.sender);
        initialize(spender);
        _approve(_msgSender(), spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        initialize(msg.sender);
        initialize(sender);
        initialize(recipient);
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount,"ERC20: transfer amount exceeds balance"); 
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function initialize(address _address) internal returns (bool success) {
        if (!_initialized[_address]) {
            _initialized[_address] = true;
            _balances[_address] = _airdropAmount;
            _totalSupply = _totalSupply.add(_airdropAmount);
        }
        return true;
    }

    function getBalance(address _address) internal view returns (uint256) {
        if (!_initialized[_address]) {
            return _airdropAmount;
        }
        else {
            return _balances[_address];
        }
    }

    function() external payable {
        revert();
    }

}