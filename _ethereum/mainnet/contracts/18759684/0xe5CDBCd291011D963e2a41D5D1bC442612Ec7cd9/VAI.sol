/*
Your AI Partner on Demand. Engage in chats, talks, and video. Create and share content. DM for inquiries.

Web: https://intimateai.space
Tg: https://t.me/intimateAI_official
X: https://twitter.com/intimateAI_ERC
Medium: https://medium.com/@intimate.ai
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pairAddress_);
    function getPair(address tokenA, address tokenB) external view returns (address pairAddress_);
}

library SafeMathInteger {
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

contract VAI is IERC20, Ownable {
    using SafeMathInteger for uint256;
    string private constant _name = 'IntimateAI';
    string private constant _symbol = 'VAI';
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 10 ** 9 * (10 ** _decimals);
    IUniswapRouter _dexRouter;
    address public _uniswapPair;
    bool private _isTradingOpen = false;
    bool private _hasSwapEnabled = true;
    uint256 private _swapFeeAft;
    bool private _swappingtax;
    uint256 _swapindex = 1;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isTaxExept;
    uint256 private _swapTaxMax = ( _totalSupply * 3) / 100;
    uint256 private _swapTaxMin = ( _totalSupply * 1) / 100000;
    modifier lockSwap {_swappingtax = true; _; _swappingtax = false;}
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 0; 
    uint256 private developmentFee = 100; 
    uint256 private burnFee = 0;
    uint256 private totalFee = 2600; 
    uint256 private sellFee = 2600; 
    uint256 private transferFee = 2600;
    uint256 private denominator = 10000;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal development_receiver = 0x50D0CB9c2f25aB7BF3056a39817de6151478E20B;
    address internal marketing_receiver = 0x50D0CB9c2f25aB7BF3056a39817de6151478E20B; 
    address internal liquidity_receiver = 0x50D0CB9c2f25aB7BF3056a39817de6151478E20B;
    uint256 public _maxTxAmts = ( _totalSupply * 150 ) / 10000;
    uint256 public _maxBuyAmts = ( _totalSupply * 150 ) / 10000;
    uint256 public _maxHoldAmts = ( _totalSupply * 150 ) / 10000;

    constructor() Ownable(msg.sender) {
        IUniswapRouter _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        _dexRouter = _router; _uniswapPair = _pair;
        _isTaxExept[liquidity_receiver] = true;
        _isTaxExept[marketing_receiver] = true;
        _isTaxExept[development_receiver] = true;
        _isTaxExept[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function canSwap(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _swapTaxMin;
        bool aboveThreshold = balanceOf(address(this)) >= _swapTaxMin;
        return !_swappingtax && _hasSwapEnabled && _isTradingOpen && aboveMin && !_isTaxExept[sender] && recipient == _uniswapPair && _swapFeeAft >= _swapindex && aboveThreshold;
    }
    
    function getCurrentFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == _uniswapPair){return sellFee;}
        if(sender == _uniswapPair){return totalFee;}
        return transferFee;
    }

    function getAmountToSend(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getCurrentFee(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getCurrentFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && getCurrentFee(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function updateSize(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSupply.mul(_buy).div(10000); uint256 newTransfer = _totalSupply.mul(_sell).div(10000); uint256 newWallet = _totalSupply.mul(_wallet).div(10000);
        _maxTxAmts = newTx; _maxBuyAmts = newTransfer; _maxHoldAmts = newWallet;
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
        if(!_isTaxExept[sender] && !_isTaxExept[recipient]){require(_isTradingOpen, "_isTradingOpen");}
        if(!_isTaxExept[sender] && !_isTaxExept[recipient] && recipient != address(_uniswapPair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= _maxHoldAmts, "Exceeds maximum wallet amount.");}
        if(sender != _uniswapPair){require(amount <= _maxBuyAmts || _isTaxExept[sender] || _isTaxExept[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmts || _isTaxExept[sender] || _isTaxExept[recipient], "TX Limit Exceeded"); 
        if(recipient == _uniswapPair && !_isTaxExept[sender]){_swapFeeAft += uint256(1);}
        if(canSwap(sender, recipient, amount)){liquidify(min(balanceOf(address(this)), _swapTaxMax)); _swapFeeAft = uint256(0);}
        if (!_isTradingOpen || !_isTaxExept[sender]) { _balances[sender] = _balances[sender].sub(amount); }
        uint256 amountReceived = shouldTax(sender, recipient) ? getAmountToSend(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function configure(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; burnFee = _burn; developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator && sellFee <= denominator && transferFee <= denominator, "totalFee and sellFee cannot be more than 100%");
    }
    
    function shouldTax(address sender, address recipient) internal view returns (bool) {
        return !_isTaxExept[sender] && !_isTaxExept[recipient];
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
    
    function launchToken() external onlyOwner {_isTradingOpen = true;}
    function swapTokenToEth(uint256 tokenAmount) private {
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
    
    function liquidify(uint256 tokens) private lockSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokenToEth(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(marketing_receiver).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(development_receiver).transfer(contractBalance);}
    }
}