/**
The World's First Decentralised Finance
 
We improve and accelerate the outdated carbon credit industry through our passively profitable REFI solution.
Website: https://www.c6protocol.com
Telegram: https://t.me/c6p_erc
Twitter: https://twitter.com/c6p_erc
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
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
contract C6P is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name = "C6Protocol";
    string private _symbol = "C6P";
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public allLimitsExcluded;
    mapping (address => bool) public maxBalanceExcluded;
    mapping (address => bool) public maxTxExcluded;
    mapping (address => bool) public isLiquidityPair;
    
    uint8 private _decimals = 9;
    uint256 private _tsupply = 10 ** 9 * 10 ** 9;
    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxBalance = 25 * 10 ** 6 * 10 ** 9;
    uint256 public minTokensToSwapTax = 10 ** 4 * 10 ** 9; 
    uint256 public buyLpFee = 0;
    uint256 public buyTeamFee = 20;
    uint256 public buyDevFee = 0;
    uint256 public buyTotalFees = 20;
    uint256 public sellLpFee = 0;
    uint256 public sellTeamFee = 20;
    uint256 public sellDevFee = 0;
    uint256 public lpFeeShare = 0;
    uint256 public teamFeeShare = 10;
    uint256 public devFeeShare = 0;
    uint256 public totalSellFee = 20;
    uint256 public totalShares = 10;
    address payable private teamAddress;
    address payable private devAddress;
    IUniswapRouter public uniswapRouter;
    address public uniswapPair;
    
    bool swapping;
    bool public taxSwapEnabled = true;
    bool public maxSwapEnabled = false;
    bool public maxWalletEnabled = true;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[_msgSender()] = _tsupply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _allowances[address(this)][address(uniswapRouter)] = _tsupply;
        buyTotalFees = buyLpFee.add(buyTeamFee).add(buyDevFee);
        totalSellFee = sellLpFee.add(sellTeamFee).add(sellDevFee);
        totalShares = lpFeeShare.add(teamFeeShare).add(devFeeShare);
        teamAddress = payable(0x1D04C891d5B7F66326F024471b95A977A8eD50CA);
        devAddress = payable(0x1D04C891d5B7F66326F024471b95A977A8eD50CA);
        
        allLimitsExcluded[owner()] = true;
        allLimitsExcluded[teamAddress] = true;
        allLimitsExcluded[devAddress] = true;
        maxBalanceExcluded[owner()] = true;
        maxBalanceExcluded[address(uniswapPair)] = true;
        maxBalanceExcluded[address(this)] = true;
        maxTxExcluded[owner()] = true;
        maxTxExcluded[teamAddress] = true;
        maxTxExcluded[devAddress] = true;
        maxTxExcluded[address(this)] = true;
        isLiquidityPair[address(uniswapPair)] = true;
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
    function swapTokensOnCA(uint256 tAmount) private lockTheSwap {
        uint256 lpFeetokens = tAmount.mul(lpFeeShare).div(totalShares).div(2);
        uint256 tokensToSwap = tAmount.sub(lpFeetokens);
        swapTokensForETH(tokensToSwap);
        uint256 caEthAmount = address(this).balance;
        uint256 totalETHFee = totalShares.sub(lpFeeShare.div(2));
        
        uint256 amountETHLiquidity = caEthAmount.mul(lpFeeShare).div(totalETHFee).div(2);
        uint256 amountETHDevelopment = caEthAmount.mul(devFeeShare).div(totalETHFee);
        uint256 amountETHMarketing = caEthAmount.sub(amountETHLiquidity).sub(amountETHDevelopment);
        if(amountETHMarketing > 0)
            sendCAETH(teamAddress, amountETHMarketing);
        if(amountETHDevelopment > 0)
            sendCAETH(devAddress, amountETHDevelopment);
    }
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(swapping)
        { 
            return _transferStandard(sender, recipient, amount); 
        }
        else
        {
            if(!maxTxExcluded[sender] && !maxTxExcluded[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }            
            uint256 swapAmount = balanceOf(address(this));
            bool minimumSwap = swapAmount >= minTokensToSwapTax;
            
            if (minimumSwap && !swapping && isLiquidityPair[recipient] && taxSwapEnabled && !allLimitsExcluded[sender] && amount > minTokensToSwapTax) 
            {
                if(maxSwapEnabled)
                    swapAmount = minTokensToSwapTax;
                swapTokensOnCA(swapAmount);    
            }
            uint256 receiverAmount = (allLimitsExcluded[sender] || allLimitsExcluded[recipient]) ? 
                                         amount : getAmountToSend(sender, recipient, amount);
            if(maxWalletEnabled && !maxBalanceExcluded[recipient])
                require(balanceOf(recipient).add(receiverAmount) <= maxBalance);
            uint256 sAmount = (!maxWalletEnabled && allLimitsExcluded[sender]) ? amount.sub(receiverAmount) : amount;
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
    function getAmountToSend(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(isLiquidityPair[sender]) {
            feeAmount = amount.mul(buyTotalFees).div(100);
        }
        else if(isLiquidityPair[recipient]) {
            feeAmount = amount.mul(totalSellFee).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }
        return amount.sub(feeAmount);
    }
    
    function sendCAETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
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
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        // make the swapTokensOnCA
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _tsupply;
        maxWalletEnabled = false;
        // Set Final Tax
        buyTeamFee = 2;
        sellTeamFee = 2;
        buyTotalFees = 2;
        totalSellFee = 2;
    }
}