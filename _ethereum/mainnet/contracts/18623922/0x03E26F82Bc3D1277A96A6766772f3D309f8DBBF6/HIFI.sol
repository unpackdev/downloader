/**
Unlock The World Of Music: Your Decentralized Sound Sanctuary

Website: https://www.hifimusic.org
Telegram: https://t.me/HiFi_erc
Twitter: https://twitter.com/HiFi_erc
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

interface IFactory {
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

interface IRouter {
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

contract HIFI is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "Hi-Fi";
    string private _symbol = "HI-FI";
    uint8 private _decimals = 9;

    uint256 private _supplyTotal = 10 ** 9 * 10 ** 9;

    uint256 public maxTxSize = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 25 * 10 ** 6 * 10 ** 9;
    uint256 public threshold = 10 ** 5 * 10 ** 9; 

    uint256 public lpBuyFee = 0;
    uint256 public mktBuyFee = 25;
    uint256 public devBuyFee = 0;

    uint256 public lpSellFee = 0;
    uint256 public mktSellFee = 25;
    uint256 public devSellFee = 0;

    uint256 public lpDiv = 0;
    uint256 public mktDiv = 10;
    uint256 public devDiv = 0;

    uint256 public tBuyTax = 25;
    uint256 public tSellTax = 25;
    uint256 public totalDividend = 10;

    address payable private taxWallet1;
    address payable private taxWallet2;

    IRouter public _router;
    address public _pair;
    
    bool _swapping;
    bool public feeSwapEnabled = true;
    bool public maxFeeSwapEnabled = false;
    bool public maxWalletEnabled = true;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcluded;
    mapping (address => bool) public isExcludedMWallet;
    mapping (address => bool) public isExcludedMTx;
    mapping (address => bool) public isPairAddress;

    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor () {
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        _pair = IFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _router = _uniswapV2Router;
        _allowances[address(this)][address(_router)] = _supplyTotal;
        taxWallet1 = payable(0x8CB1a5a9528d87CD6AdFf09A49EF4e2D7752c91A);
        taxWallet2 = payable(0x8CB1a5a9528d87CD6AdFf09A49EF4e2D7752c91A);
        isExcluded[owner()] = true;
        isExcluded[taxWallet1] = true;
        isExcluded[taxWallet2] = true;
        tBuyTax = lpBuyFee.add(mktBuyFee).add(devBuyFee);
        tSellTax = lpSellFee.add(mktSellFee).add(devSellFee);
        totalDividend = lpDiv.add(mktDiv).add(devDiv);
        isExcludedMWallet[owner()] = true;
        isExcludedMWallet[address(_pair)] = true;
        isExcludedMWallet[address(this)] = true;
        isExcludedMTx[owner()] = true;
        isExcludedMTx[taxWallet1] = true;
        isExcludedMTx[taxWallet2] = true;
        isExcludedMTx[address(this)] = true;
        isPairAddress[address(_pair)] = true;
        _balances[_msgSender()] = _supplyTotal;
        emit Transfer(address(0), _msgSender(), _supplyTotal);
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
        return _supplyTotal;
    }

    receive() external payable {}

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
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function swapBack(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount.mul(lpDiv).div(totalDividend).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensToEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = totalDividend.sub(lpDiv.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(lpDiv).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = amountReceived.mul(devDiv).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHDevelopment);

        if(amountETHMarketing > 0)
            sendETH(taxWallet1, amountETHMarketing);

        if(amountETHDevelopment > 0)
            sendETH(taxWallet2, amountETHDevelopment);

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
            feeAmount = amount.mul(tBuyTax).div(100);
        }
        else if(isPairAddress[recipient]) {
            feeAmount = amount.mul(tSellTax).div(100);
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
            if(!isExcludedMTx[sender] && !isExcludedMTx[recipient]) {
                require(amount <= maxTxSize, "Transfer amount exceeds the maxTxSize.");
            }            

            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= threshold;
            
            if (minimumSwap && !_swapping && isPairAddress[recipient] && feeSwapEnabled && !isExcluded[sender] && amount > threshold) 
            {
                if(maxFeeSwapEnabled)
                    swapAmount = threshold;
                swapBack(swapAmount);    
            }

            uint256 receiverAmount = (isExcluded[sender] || isExcluded[recipient]) ? 
                                         amount : takeFee(sender, recipient, amount);

            if(maxWalletEnabled && !isExcludedMWallet[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWallet);

            uint256 sAmount = (!maxWalletEnabled && isExcluded[sender]) ? amount.sub(receiverAmount) : amount;
            _balances[sender] = _balances[sender].sub(sAmount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(receiverAmount);

            emit Transfer(sender, recipient, receiverAmount);
            return true;
        }
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
    
    function sendETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxSize = _supplyTotal;
        maxWalletEnabled = false;
        mktBuyFee = 1;
        mktSellFee = 1;
        tBuyTax = 1;
        tSellTax = 1;
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
}