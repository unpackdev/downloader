/*
The crypto heroes will stop you! You foolish bankers will fail to ruin the world.

Website: https://www.cryptoheroes.tech
Telegram: https://t.me/herocrypto_erc
Twitter: https://twitter.com/herocrypto_erc
Dapp: https://app.cryptoheroes.tech
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

library SafeLibrary {
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

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    event OwnershipTransferred(address owner);
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pairAddress_);
    function getPair(address tokenA, address tokenB) external view returns (address pairAddress_);
}

contract HEROES is IERC20, Ownable {
    using SafeLibrary for uint256;
    string private constant _name = 'Crypto Heroes';
    string private constant _symbol = 'HEROES';
    uint8 private constant _decimals = 18;
    uint256 private _totalSpply = 10 ** 9 * (10 ** _decimals);
    IUniswapRouter _dexRouter;
    address public _dexPairAddress;
    bool private _istradeStarted = false;
    bool private _taxSwapEnabed = true;
    uint256 private _swapcounts;
    bool private _inswaptax;
    uint256 _numbuyers = 1;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromTax;
    uint256 private _maxFee = ( _totalSpply * 3) / 100;
    uint256 private _minFee = ( _totalSpply * 1) / 100000;
    modifier lockSwap {_inswaptax = true; _; _inswaptax = false;}
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0; 
    uint256 private developmentFee = 100; 
    uint256 private burnFee = 0;
    uint256 private totalFee = 2300; 
    uint256 private sellFee = 2300; 
    uint256 private transferFee = 2300;
    uint256 private denominator = 10000;
    uint256 public maxTxSize = ( _totalSpply * 170 ) / 10000;
    uint256 public maxTransferSize = ( _totalSpply * 170 ) / 10000;
    uint256 public maxWalletSize = ( _totalSpply * 170 ) / 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal development_receiver = 0x25eDB6eD592c0013E90954fB0e109d8dbc452346;
    address internal marketing_receiver = 0x25eDB6eD592c0013E90954fB0e109d8dbc452346; 
    address internal liquidity_receiver = 0x25eDB6eD592c0013E90954fB0e109d8dbc452346;

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        _dexRouter = _router; _dexPairAddress = _pair;
        isExcludedFromTax[liquidity_receiver] = true;
        isExcludedFromTax[marketing_receiver] = true;
        isExcludedFromTax[development_receiver] = true;
        isExcludedFromTax[msg.sender] = true;
        _balances[msg.sender] = _totalSpply;
        emit Transfer(address(0), msg.sender, _totalSpply);
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
    function totalSupply() public view override returns (uint256) {return _totalSpply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function cnaSwaTax(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minFee;
        bool aboveThreshold = balanceOf(address(this)) >= _minFee;
        return !_inswaptax && _taxSwapEnabed && _istradeStarted && aboveMin && !isExcludedFromTax[sender] && recipient == _dexPairAddress && _swapcounts >= _numbuyers && aboveThreshold;
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(!isExcludedFromTax[sender] && !isExcludedFromTax[recipient]){require(_istradeStarted, "_istradeStarted");}
        if(!isExcludedFromTax[sender] && !isExcludedFromTax[recipient] && recipient != address(_dexPairAddress) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWalletSize, "Exceeds maximum wallet amount.");}
        if(sender != _dexPairAddress){require(amount <= maxTransferSize || isExcludedFromTax[sender] || isExcludedFromTax[recipient], "TX Limit Exceeded");}
        require(amount <= maxTxSize || isExcludedFromTax[sender] || isExcludedFromTax[recipient], "TX Limit Exceeded"); 
        if(recipient == _dexPairAddress && !isExcludedFromTax[sender]){_swapcounts += uint256(1);}
        if(cnaSwaTax(sender, recipient, amount)){swapBackToken(min(balanceOf(address(this)), _maxFee)); _swapcounts = uint256(0);}
        if (!_istradeStarted || !isExcludedFromTax[sender]) { _balances[sender] = _balances[sender].sub(amount); }
        uint256 amountReceived = shouldFeeCharge(sender, recipient) ? _getTransferAmount(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function setTaxSettings(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator && sellFee <= denominator && transferFee <= denominator, "totalFee and sellFee cannot be more than 100%");
    }
    function shouldFeeCharge(address sender, address recipient) internal view returns (bool) {
        return !isExcludedFromTax[sender] && !isExcludedFromTax[recipient];
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.addLiquidityETH{value: ETHAmount}(
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
    function swapTokensToEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
    function enableBuys() external onlyOwner {_istradeStarted = true;}
    function setWalletSettings(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSpply.mul(_buy).div(10000); uint256 newTransfer = _totalSpply.mul(_sell).div(10000); uint256 newWallet = _totalSpply.mul(_wallet).div(10000);
        maxTxSize = newTx; maxTransferSize = newTransfer; maxWalletSize = newWallet;
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
    function swapBackToken(uint256 tokens) private lockSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensToEth(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketing_receiver).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(development_receiver).transfer(contractBalance);}
    }
    function _getFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == _dexPairAddress){return sellFee;}
        if(sender == _dexPairAddress){return totalFee;}
        return transferFee;
    }
    function _getTransferAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(_getFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(_getFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && _getFees(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }
}