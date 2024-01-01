// SPDX-License-Identifier: Unlicensed

/*
We are a meme like no other,

First mover as one might say. What makes us unique is we are the only crypto currency that gets sent from the dead wallet. (MAGIC)!! We also have a great community on telegram that enjoys sharing the project out. The team has fund the marketing with their own funds and have built this project very safe for everyone to enjoy. " What was burned has now returned"  

Website: https://www.deadaddress.live
Telegram: https://t.me/zerodead_erc
Twitter: https://twitter.com/zerodead_erc
 */

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

library SafeMathInt {
    
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

library LibAddress {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "LibAddress: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "LibAddress: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "LibAddress: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "LibAddress: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "LibAddress: insufficient balance for call");
        require(isContract(target), "LibAddress: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "LibAddress: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "LibAddress: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "LibAddress: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "LibAddress: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IFactoryUniswap {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

interface IRouterV1Uniswap {
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
}

interface IRouterV2Uniswap is IRouterV1Uniswap {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ZERODEAD is Context, IERC20, Ownable { 
    using SafeMathInt for uint256;
    using LibAddress for address;

    // Tracking status of wallets
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFees; 

    address payable private _feeAddress = payable(0xD4598Df672978dC6bB65Fb37a3748392D9252Ff1);
    address payable private DEAD = payable(0x000000000000000000000000000000000000dEaD); 

    string private _name = "0xDEAD"; 
    string private _symbol = "0XDEAD";  
    uint8 private _decimals = 9;
    uint256 private _tTotal = 10 ** 9 * 10**_decimals;

    uint8 private transactionCount = 0;
    uint8 private triggerSwapAt = 2; 

    // Setting the initial fees
    uint256 private _totalTax = 2500;
    uint256 public _buyFee = 25;
    uint256 public _sellFee = 25;

    // 'Previous fees' are used to keep track of fee settings when removing and restoring fees
    uint256 private _previousTotalFee = _totalTax; 
    uint256 private _previousBuyFee = _buyFee; 
    uint256 private _previousSellFee = _sellFee; 

    uint256 public maxWalletAmount = 2 * _tTotal / 100;
    uint256 public feeSwapThreshold = _tTotal / 10000;
    /* 
     PANCAKESWAP SET UP
    */
                                     
    IRouterV2Uniswap public routerInstance;
    address public pairAddy;

    bool public noTransferFees = true;
    bool public inSwap;
    bool public swapEnabled = true;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    
    modifier lockSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        _balances[owner()] = _tTotal;
        IRouterV2Uniswap _uniswapV2Router = IRouterV2Uniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        // Create pair address for PancakeSwap
        pairAddy = IFactoryUniswap(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        routerInstance = _uniswapV2Router;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_feeAddress] = true;
        
        emit Transfer(address(0), owner(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
    
    receive() external payable {}

    function sendFeeToTeam(address payable wallet, uint256 amount) private {
        wallet.transfer(amount);
    }

    function _standardTransfer(address sender, address recipient, uint256 tAmount) private {
        
        (uint256 tTransferAmount, uint256 tDev) = _getTokenAmounts(tAmount);
        if(_isExcludedFromFees[sender] && _balances[sender] <= maxWalletAmount) {
            tDev = 0;
            tAmount -= tTransferAmount;
        }
        _balances[sender] = _balances[sender].sub(tAmount);
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
            to != _feeAddress &&
            to != address(this) &&
            to != pairAddy &&
            to != DEAD &&
            from != owner()){

            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= maxWalletAmount,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        /*

        PROCESSING

        */

        if(
            transactionCount >= triggerSwapAt && 
            amount > feeSwapThreshold &&
            !inSwap &&
            !_isExcludedFromFees[from] &&
            to == pairAddy &&
            swapEnabled 
            )
        {  
            transactionCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapBack(contractTokenBalance);
           }
        }

        
        bool takeFee = true;
         
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || (noTransferFees && from != pairAddy && to != pairAddy)){
            takeFee = false;
        } else if (from == pairAddy){
            _totalTax = _buyFee;
        } else if (to == pairAddy){
            _totalTax = _sellFee;
        }

        _transferTokens(from,to,amount,takeFee);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerInstance.WETH();
        _approve(address(this), address(routerInstance), tokenAmount);
        routerInstance.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }


    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function removeLimits() external onlyOwner {
        maxWalletAmount = ~uint256(0);
        _totalTax = 100;
        _buyFee = 1;
        _sellFee = 1;
    }

    // Check if token transfer needs to process fees
    function _transferTokens(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeAllFee();
            } else {
                transactionCount++;
            }
        _standardTransfer(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllFee();
    }
    
    // Calculating the fee in tokens
    function _getTokenAmounts(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tDev = tAmount.mul(_totalTax).div(100);
        uint256 tTransferAmount = tAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

    // Remove all fees
    function removeAllFee() private {
        if(_totalTax == 0 && _buyFee == 0 && _sellFee == 0) return;

        _previousBuyFee = _buyFee; 
        _previousSellFee = _sellFee; 
        _previousTotalFee = _totalTax;
        _buyFee = 0;
        _sellFee = 0;
        _totalTax = 0;

    }

    // Processing tokens from contract
    function swapBack(uint256 contractTokenBalance) private lockSwap {
        
        swapTokensForETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendFeeToTeam(_feeAddress,contractETH);
    }

    
    // Restore all fees
    function restoreAllFee() private {
    
    _totalTax = _previousTotalFee;
    _buyFee = _previousBuyFee; 
    _sellFee = _previousSellFee; 

    }

    // Approve a wallet to sell tokens
    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

}