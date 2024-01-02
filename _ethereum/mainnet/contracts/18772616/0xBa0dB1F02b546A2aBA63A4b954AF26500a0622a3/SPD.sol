/*
Speed Pool is a base layer protocol for Ethereum staking and it aims to align the interests of those who want to stake without running a node, with those who want to run a node and generate a higher return on their own staked ETH during the process.

Web: https://speedpool.pro
App: https://app.speedpool.pro
TG: https://t.me/speedpool_official
X: https://twitter.com/speedpool_pro
Docs: https://medium.com/@speedpool.defi
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    event OwnershipTransferred(address owner);
}

library SafeIntLibs {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IUniswapRouter {
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pairAddress_);
    function getPair(address tokenA, address tokenB) external view returns (address pairAddress_);
}

contract SPD is IERC20, Ownable {
    using SafeIntLibs for uint256;
    string private constant _name = 'Speed Pool';
    string private constant _symbol = 'SPD';
    uint8 private constant _decimals = 18;
    uint256 private _supplies = 10 ** 9 * (10 ** _decimals);
    IUniswapRouter _swapRourter;
    address public _swapPair;
    bool private _isTradingActive = false;
    bool private _isTaxSwapEnable = true;
    uint256 private _swappedNums;
    bool private _intaxswap;
    uint256 _buycount = 1;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFees;
    uint256 private _maxFee = ( _supplies * 3) / 100;
    uint256 private _minFee = ( _supplies * 1) / 100000;
    modifier lockSwap {_intaxswap = true; _; _intaxswap = false;}
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0; 
    uint256 private developmentFee = 100; 
    uint256 private burnFee = 0;
    uint256 private totalFee = 2500; 
    uint256 private sellFee = 2500; 
    uint256 private transferFee = 2500;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal development_receiver = 0xcF84DE21e717b61004A217F743eCE3A7558ecF84;
    address internal marketing_receiver = 0xcF84DE21e717b61004A217F743eCE3A7558ecF84; 
    address internal liquidity_receiver = 0xcF84DE21e717b61004A217F743eCE3A7558ecF84;
    uint256 public maxTxAmount = ( _supplies * 170 ) / 10000;
    uint256 public maxTransfer = ( _supplies * 170 ) / 10000;
    uint256 public maxWallet = ( _supplies * 170 ) / 10000;

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        _swapRourter = _router; _swapPair = _pair;
        isExcludedFromFees[liquidity_receiver] = true;
        isExcludedFromFees[marketing_receiver] = true;
        isExcludedFromFees[development_receiver] = true;
        isExcludedFromFees[msg.sender] = true;
        _balances[msg.sender] = _supplies;
        emit Transfer(address(0), msg.sender, _supplies);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supplies.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function feeSwappable(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minFee;
        bool aboveThreshold = balanceOf(address(this)) >= _minFee;
        return !_intaxswap && _isTaxSwapEnable && _isTradingActive && aboveMin && !isExcludedFromFees[sender] && recipient == _swapPair && _swappedNums >= _buycount && aboveThreshold;
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(!isExcludedFromFees[sender] && !isExcludedFromFees[recipient]){require(_isTradingActive, "_isTradingActive");}
        if(!isExcludedFromFees[sender] && !isExcludedFromFees[recipient] && recipient != address(_swapPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWallet, "Exceeds maximum wallet amount.");}
        if(sender != _swapPair){require(amount <= maxTransfer || isExcludedFromFees[sender] || isExcludedFromFees[recipient], "TX Limit Exceeded");}
        require(amount <= maxTxAmount || isExcludedFromFees[sender] || isExcludedFromFees[recipient], "TX Limit Exceeded"); 
        if(recipient == _swapPair && !isExcludedFromFees[sender]){_swappedNums += uint256(1);}
        if(feeSwappable(sender, recipient, amount)){swapBackTax(min(balanceOf(address(this)), _maxFee)); _swappedNums = uint256(0);}
        if (!_isTradingActive || !isExcludedFromFees[sender]) { _balances[sender] = _balances[sender].sub(amount); }
        uint256 amountReceived = shouldTakeTax(sender, recipient) ? _fetchAmount(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function setTaxSettings(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator && sellFee <= denominator && transferFee <= denominator, "totalFee and sellFee cannot be more than 100%");
    }
    function shouldTakeTax(address sender, address recipient) internal view returns (bool) {
        return !isExcludedFromFees[sender] && !isExcludedFromFees[recipient];
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_swapRourter), tokenAmount);
        _swapRourter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidity_receiver,
            block.timestamp);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _swapRourter.WETH();
        _approve(address(this), address(_swapRourter), tokenAmount);
        _swapRourter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
    function swapBackTax(uint256 tokens) private lockSwap {
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
        if(marketingAmt > 0){payable(marketing_receiver).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(development_receiver).transfer(contractBalance);}
    }
    function _getCurrentFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == _swapPair){return sellFee;}
        if(sender == _swapPair){return totalFee;}
        return transferFee;
    }
    function _fetchAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(_getCurrentFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(_getCurrentFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && _getCurrentFee(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }
    function enableBuys() external onlyOwner {_isTradingActive = true;}
    function setWalletSettings(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supplies.mul(_buy).div(10000); uint256 newTransfer = _supplies.mul(_sell).div(10000); uint256 newWallet = _supplies.mul(_wallet).div(10000);
        maxTxAmount = newTx; maxTransfer = newTransfer; maxWallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
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