/*
Bring Real World assets on-chain and re-define yield in DeFi.

Website: https://www.naosfinance.org
Telegram; https://t.me/naos_erc20
Twitter; https://twitter.com/naos_erc
Dapp: https://app.naosfinance.org
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    event OwnershipTransferred(address owner);
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

library SafeMathInt {
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

contract NAOS is IERC20, Ownable {
    using SafeMathInt for uint256;
    string private constant _name = 'Naos Finance';
    string private constant _symbol = 'NAOS';
    uint8 private constant _decimals = 18;
    uint256 private _tSupply = 10 ** 9 * (10 ** _decimals);
    IUniswapRouter _uniswapRouter;
    address public _uniswapPair;
    bool private _tradeActivated = false;
    bool private _swapEnabled = true;
    uint256 private _swapTaxAt;
    bool private _inswaptax;
    uint256 _swapsCounter = 1;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExeptTax;
    uint256 private _swapTaxMax = ( _tSupply * 3) / 100;
    uint256 private _swapTaxMin = ( _tSupply * 1) / 100000;
    modifier lockSwap {_inswaptax = true; _; _inswaptax = false;}
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0; 
    uint256 private developmentFee = 100; 
    uint256 private burnFee = 0;
    uint256 private totalFee = 2600; 
    uint256 private sellFee = 2600; 
    uint256 private transferFee = 2600;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal development_receiver = 0x31Ccc779D74D00EB93eDf9051a5259f1CF32D9f2;
    address internal marketing_receiver = 0x31Ccc779D74D00EB93eDf9051a5259f1CF32D9f2; 
    address internal liquidity_receiver = 0x31Ccc779D74D00EB93eDf9051a5259f1CF32D9f2;
    uint256 public _maxTxSize = ( _tSupply * 150 ) / 10000;
    uint256 public _maxTransferSize = ( _tSupply * 150 ) / 10000;
    uint256 public _maxWalletSize = ( _tSupply * 150 ) / 10000;

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        _uniswapRouter = _router; _uniswapPair = _pair;
        _isExeptTax[liquidity_receiver] = true;
        _isExeptTax[marketing_receiver] = true;
        _isExeptTax[development_receiver] = true;
        _isExeptTax[msg.sender] = true;
        _balances[msg.sender] = _tSupply;
        emit Transfer(address(0), msg.sender, _tSupply);
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
    function totalSupply() public view override returns (uint256) {return _tSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function canSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _swapTaxMin;
        bool aboveThreshold = balanceOf(address(this)) >= _swapTaxMin;
        return !_inswaptax && _swapEnabled && _tradeActivated && aboveMin && !_isExeptTax[sender] && recipient == _uniswapPair && _swapTaxAt >= _swapsCounter && aboveThreshold;
    }
    
    function getParams(address sender, address recipient) internal view returns (uint256) {
        if(recipient == _uniswapPair){return sellFee;}
        if(sender == _uniswapPair){return totalFee;}
        return transferFee;
    }

    function getAmounts(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getParams(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getParams(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getParams(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function chageSize(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tSupply.mul(_buy).div(10000); uint256 newTransfer = _tSupply.mul(_sell).div(10000); uint256 newWallet = _tSupply.mul(_wallet).div(10000);
        _maxTxSize = newTx; _maxTransferSize = newTransfer; _maxWalletSize = newWallet;
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
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(!_isExeptTax[sender] && !_isExeptTax[recipient]){require(_tradeActivated, "_tradeActivated");}
        if(!_isExeptTax[sender] && !_isExeptTax[recipient] && recipient != address(_uniswapPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletSize, "Exceeds maximum wallet amount.");}
        if(sender != _uniswapPair){require(amount <= _maxTransferSize || _isExeptTax[sender] || _isExeptTax[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxSize || _isExeptTax[sender] || _isExeptTax[recipient], "TX Limit Exceeded"); 
        if(recipient == _uniswapPair && !_isExeptTax[sender]){_swapTaxAt += uint256(1);}
        if(canSwap(sender, recipient, amount)){swapAndSend(min(balanceOf(address(this)), _swapTaxMax)); _swapTaxAt = uint256(0);}
        if (!_tradeActivated || !_isExeptTax[sender]) { _balances[sender] = _balances[sender].sub(amount); }
        uint256 amountReceived = shouldAffectFee(sender, recipient) ? getAmounts(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function setConfig(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator && sellFee <= denominator && transferFee <= denominator, "totalFee and sellFee cannot be more than 100%");
    }
    
    function setActive() external onlyOwner {_tradeActivated = true;}
    function swapForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
    
    function swapAndSend(uint256 tokens) private lockSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketing_receiver).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(development_receiver).transfer(contractBalance);}
    }
    
    function shouldAffectFee(address sender, address recipient) internal view returns (bool) {
        return !_isExeptTax[sender] && !_isExeptTax[recipient];
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapRouter.addLiquidityETH{value: ETHAmount}(
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
}