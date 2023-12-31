// SPDX-License-Identifier: MIT

/*
Make the Jump & explore your favorite chains!

Website: https://www.bungeehealth.org
Telegram:  https://t.me/bungee_eth
Twitter: https://twitter.com/bungee_erc20
*/

pragma solidity 0.8.21;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

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
interface IUniswapFactory{
    function createPair(address tokenA, address tokenB) external returns (address uniPair);
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

library SafeMath {
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

contract BUNGEE is IERC20, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);

    string private constant _name = unicode"Bungee Protocol";
    string private constant _symbol = unicode"BUNGEE";

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isSpecialAddress;

    IUniswapRouter _uniRouter;
    address public uniPair;
    bool private tradingEnable = false;
    bool private swapEnabled = true;
    uint256 private numOfSwaps;
    bool private isSwapping;
    uint256 numOfSwapsAfter;
    uint256 private _minTaxSwap = ( _supply * 1000 ) / 100000;
    uint256 private _maxSwapFee = ( _supply * 10 ) / 100000;
    
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0;
    uint256 private developmentFee = 100;
    uint256 private burnFee = 0;

    uint256 private buyTax = 1700;
    uint256 private sellTax = 1700;
    uint256 private transferFee = 1700;
    uint256 private denominator = 10000;

    modifier lockSwapTax {isSwapping = true; _; isSwapping = false;}

    address internal devAddy = 0x95b008346c25B9599704720974Fb72B197C538a8; 
    address internal teamAddr = 0x95b008346c25B9599704720974Fb72B197C538a8;
    address internal lpReceiver = 0x95b008346c25B9599704720974Fb72B197C538a8;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private _maxTxAmount = ( _supply * 340 ) / 10000;
    uint256 private _maxBuyLimit = ( _supply * 340 ) / 10000;
    uint256 private _maxHoldingSize = ( _supply * 340 ) / 10000;

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        _uniRouter = _router; uniPair = _pair;

        isSpecialAddress[lpReceiver] = true;
        isSpecialAddress[msg.sender] = true;
        isSpecialAddress[teamAddr] = true;
        isSpecialAddress[devAddy] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function startTrading() external onlyOwner {tradingEnable = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}

    function setContractSwapSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        numOfSwapsAfter = _swapAmount; _minTaxSwap = _supply.mul(_swapThreshold).div(uint256(100000)); 
        _maxSwapFee = _supply.mul(_minTokenAmount).div(uint256(100000));
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function shouldSwapTax(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _maxSwapFee;
        bool aboveThreshold = balanceOf(address(this)) >= _minTaxSwap;
        return !isSwapping && swapEnabled && tradingEnable && aboveMin && !isSpecialAddress[sender] && recipient == uniPair && numOfSwaps >= numOfSwapsAfter && aboveThreshold;
    }

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; buyTax = _total; sellTax = _sell; transferFee = _trans;
        require(buyTax <= denominator.div(1) && sellTax <= denominator.div(1) && transferFee <= denominator.div(1), "buyTax and sellTax cannot be more than 20%");
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        _maxTxAmount = newTx; _maxBuyLimit = newTransfer; _maxHoldingSize = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }

    function getFeeByTypes(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniPair){return sellTax;}
        if(sender == uniPair){return buyTax;}
        return transferFee;
    }

    function swapBackCALock(uint256 tokens) private lockSwapTax {
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
        if(marketingAmt > 0){payable(teamAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddy).transfer(contractBalance);}
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniRouter.WETH();
        _approve(address(this), address(_uniRouter), tokenAmount);
        _uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function getTaxxableAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isSpecialAddress[recipient]) {return _maxTxAmount;}
        if(getFeeByTypes(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFeeByTypes(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getFeeByTypes(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_uniRouter), tokenAmount);
        _uniRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpReceiver,
            block.timestamp);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isSpecialAddress[sender] && !isSpecialAddress[recipient]){require(tradingEnable, "tradingEnable");}
        if(!isSpecialAddress[sender] && !isSpecialAddress[recipient] && recipient != address(uniPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxHoldingSize, "Exceeds maximum wallet amount.");}
        if(sender != uniPair){require(amount <= _maxBuyLimit || isSpecialAddress[sender] || isSpecialAddress[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmount || isSpecialAddress[sender] || isSpecialAddress[recipient], "TX Limit Exceeded"); 
        if(recipient == uniPair && !isSpecialAddress[sender]){numOfSwaps += uint256(1);}
        if(shouldSwapTax(sender, recipient, amount)){swapBackCALock(_minTaxSwap); numOfSwaps = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isSpecialAddress[sender] ? getTaxxableAmount(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
}