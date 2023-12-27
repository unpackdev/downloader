/**
TG: https://t.me/twolandstokenportal
Website: https://twolandstoken.com/
Author: @bLock_doctor
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;
 
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
interface IUniRouterV1
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniRouterV2 is IUniRouterV1
{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(msg.sender==owner(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }
}
 
contract TwoLands is IERC20, Ownable {
 
    uint8 private _buyTax = 5;
    uint8 private _sellTax = 5;
    uint8 private constant START_TAX = 90;
    uint8 private constant TAX_DECREMENT = 10;
    uint8 private constant _decimals = 18;
 
    uint16 private _liquidityTax = 30;
    uint16 private _marketingTax = 35;
    uint16 private _operationsTax = 35; 
 
    uint256 private constant _totalSupply = 1000000000 * 10 ** _decimals;
    uint256 private _swapTokenThreshold = 500000 * 10 ** _decimals;
    uint256 private _maxWallet = 5000000 * 10 ** _decimals;
    uint256 private _maxTransaction = 5000000 * 10 ** _decimals;
    uint256 private _tradingEnabledTimeStamp;
    uint256 private constant DECREMENT_INTERVAL = 1 minutes;
 
    bool private _tradingEnabled;
    bool private _swapEnabled;
    bool private _inSwap;
 
    string private constant _tokenName = "Two Lands";
    string private constant _tokenSymbol = "LANDS";
 
    IUniRouterV2 private _router;
    address private _pairAddress;
    address public constant burnWallet = address(0xdead);
    address public constant zeroAddress = address(0);
    address public marketingWallet = 0xcea821B9aDd4949e4a9703b87DF70E37039b884c;
    address public operationsWallet = 0xe96AE647dac359DB5c0c3afc41e73a7E7C6A731C;
 
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _excludedFromFees;
    mapping(address => bool) private _automatedMarketMakers;
    mapping(address => mapping (address => uint256)) private _allowances;
 
    modifier LockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }
 
    event SwapAndLiquify(
        uint256 liquidityTokens,
        uint256 liquidityETH
    );
 
    constructor() {
        _router = IUniRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _pairAddress = IDEXFactory(_router.factory()).createPair(_router.WETH(), address(this));
        _allowances[address(this)][address(_router)] = type(uint256).max;
        _automatedMarketMakers[_pairAddress] = true;
        _excludedFromFees[msg.sender] = true;
        _excludedFromFees[address(this)] = true;
        _excludedFromFees[burnWallet] = true;
        _excludedFromFees[zeroAddress] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        bool isExcluded = _excludedFromFees[from] || _excludedFromFees[to];
        bool isBuy = _automatedMarketMakers[from];
        bool isSell = _automatedMarketMakers[to];
        if (isExcluded) _transferTokens(from, to, amount, 0);
        else {
            require(_tradingEnabled, "Trading is not enabled!");
            if (isBuy) _buyTokens(from, to, amount);
            else if (isSell) {
                if (_swapEnabled && !_inSwap) _swapAndLiquify(false);
                _sellTokens(from, to, amount);
            } else _transferTokens(from, to, amount, 0);
        }
    }
 
    function _getBuyTax() private view returns (uint8) {
        uint256 timeElapsed = block.timestamp - _tradingEnabledTimeStamp;
        uint256 decrements = timeElapsed / DECREMENT_INTERVAL;
        if (decrements < 8) {
            return uint8(START_TAX - (decrements * TAX_DECREMENT));
        } else {
            return _buyTax;
        }
    }
 
    function _buyTokens(
        address from,
        address to,
        uint256 amount
    ) private {
        require(amount <= _maxTransaction, "Cannot exceed max transaction.");
        require(_balances[to] + amount <= _maxWallet, "Cannot exceed max wallet.");
        _transferTokens(from, to, amount, _getBuyTax());
    }
 
    function _sellTokens(
        address from,
        address to,
        uint256 amount
    ) private {
        require(amount <= _maxTransaction, "Cannot exceed max transaction.");
        _transferTokens(from, to, amount, _sellTax);
    }
 
    function _transferTokens(
        address from,
        address to,
        uint256 amount,
        uint8 taxPercent
    ) private {
        uint256 taxedTokens = amount * taxPercent / 100;
        _balances[from] -= amount;
        _balances[address(this)] += taxedTokens;
        _balances[to] += (amount - taxedTokens);
        emit Transfer(from, to, (amount - taxedTokens));
    }
 
    function _swapAndLiquify(
        bool ignoreLimits
    ) private LockTheSwap {
        uint256 contractTokenBalance = _balances[address(this)];
        uint256 toSwap = _swapTokenThreshold;
        if (contractTokenBalance < toSwap) {
            if (ignoreLimits && contractTokenBalance > 0) {
                toSwap = contractTokenBalance;
            } else return;
        }
        uint256 totalLiquidityTokens = toSwap * _liquidityTax / 100;
        uint256 tokensRemaining = toSwap - totalLiquidityTokens;
        uint256 liquidityTokens = totalLiquidityTokens / 2;
        uint256 liquidityETHTokens = totalLiquidityTokens - liquidityTokens;
        toSwap = tokensRemaining + liquidityETHTokens;
        uint256 oldETH = address(this).balance;
        _swapTokensForETH(toSwap);
        uint256 newETH = address(this).balance - oldETH;
        uint256 liquidityETH = (newETH * liquidityETHTokens) / toSwap;
        uint256 remainingETH = newETH - liquidityETH;
        uint256 operationsETH = remainingETH * _operationsTax / 100;
        uint256 marketingETH = remainingETH - operationsETH;
        (bool transferOperations,) = payable(operationsWallet).call{value: operationsETH, gas: 30000}("");
        transferOperations = false;
        (bool transferMarketing,) = payable(marketingWallet).call{value: marketingETH, gas: 30000}("");
        transferMarketing = false;
        _addLiquidity(liquidityTokens,liquidityETH);
        emit SwapAndLiquify(
            liquidityTokens,
            liquidityETH
        );
    }
 
    // ROUTER FUNCTIONS \\
 
    function _swapTokensForETH(
        uint256 tokenAmount
    ) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    function _addLiquidity(
        uint256 tokenAmount,
        uint256 amountWei
    ) private {
        _approve(address(this), address(_router), tokenAmount);
        _router.addLiquidityETH{value: amountWei}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }
 
    // END OF ROUTER FUNCTIONS \\
 
    // OWNER FUNCTIONS \\
 
    function ownerEnableTrading() public onlyOwner {
        require(!_tradingEnabled, "Trading is already enabled!");
        _tradingEnabledTimeStamp = block.timestamp;
        _tradingEnabled = true;
    }
 
    function ownerExcludeFromFees(
        address wallet,
        bool excluded
    ) public onlyOwner {
        _excludedFromFees[wallet] = excluded;
    }
 
    function ownerUpdateAMM(
        address marketMaker,
        bool enabled
    ) public onlyOwner {
        require(marketMaker != _pairAddress, "Cannot disable pair address!");
        _automatedMarketMakers[marketMaker] = enabled;
    }
 
    function ownerUpdatePrimaryTaxes(
        uint8 buyTax,
        uint8 sellTax
    ) public onlyOwner {
        require(buyTax + sellTax <= 20, "Taxes cannot exceed 10!");
        _buyTax = buyTax;
        _sellTax = sellTax;
    }
 
    function ownerUpdateSwapTaxes(
        uint16 liquidityTax,
        uint16 marketingTax,
        uint16 operationsTax
    ) public onlyOwner {
        require(
            liquidityTax > 0 &&
            marketingTax > 0 &&
            operationsTax > 0 &&
            liquidityTax + marketingTax + operationsTax == 100,
            "Each tax must be greater than zero, and must equal to 100!"
        );
        _liquidityTax = liquidityTax;
        _marketingTax = marketingTax;
        _operationsTax = operationsTax;
    }
 
    function ownerUpdateMaxWallet(
        uint256 maxWallet
    ) public onlyOwner {
        require(maxWallet >= 5000000, "Max wallet cannot be lower than 0.5 percent!");
        _maxWallet = maxWallet * 10 ** _decimals;
    }
 
    function ownerUpdateMaxTransaction(
        uint256 maxTransaction
    ) public onlyOwner {
        require(maxTransaction >= 5000000, "Max transaction cannot be lower than 0.5 percent!");
        _maxTransaction = maxTransaction * 10 ** _decimals;
    }
 
    function ownerToggleSwap(
        bool swapEnabled
    ) public onlyOwner {
        _swapEnabled = swapEnabled;
    }
 
    function ownerSetSwapThreshold(
        uint256 swapTokenThreshold
    ) public onlyOwner {
        require(
            swapTokenThreshold > 0 &&
            swapTokenThreshold <= 1000000,
            "Swap threshold cannot be zero, and cannot exceed 0.5 percent!"
        );
        _swapTokenThreshold = swapTokenThreshold * 10 ** _decimals;
    }
 
    function ownerTriggerSwap(
        bool ignoreLimits
    ) public onlyOwner {
        _swapAndLiquify(ignoreLimits);
    }
 
    function ownerUpdateMarketingWallet(
        address newMarketingWallet
    ) public onlyOwner {
        require(
            newMarketingWallet != address(this) &&
            newMarketingWallet != address(0) &&
            newMarketingWallet != address(0xdead),
            "Cannot set marketing wallet to zero or dead address!"
        );
        marketingWallet = newMarketingWallet;
    }
 
    function ownerUpdateOperationsWallet(
        address newOperationsWallet
    ) public onlyOwner {
        require(
            newOperationsWallet != address(this) &&
            newOperationsWallet != address(0) &&
            newOperationsWallet != address(0xdead),
            "Cannot set operations wallet to zero or dead address!"
        );
        operationsWallet = newOperationsWallet;
    }
 
    function ownerWithdrawStrandedToken(
        address strandedToken
    ) public onlyOwner {
        require(strandedToken != address(this), "Cannot withdraw native token!");
        IERC20 token = IERC20(strandedToken);
        token.transfer(owner(), token.balanceOf(address(this)));
    }
 
    function ownerWithdrawStuckETH() public onlyOwner {
        (bool success,) = msg.sender.call{value:(address(this).balance)}("");
        require(success);
    }
 
    // END OF OWNER FUNCTIONS \\
 
    // START OF GETTERS \\
 
    function showPrimaryTaxes() public view returns (
        uint8 buyTax,
        uint8 sellTax
    ) {
        buyTax = _getBuyTax();
        sellTax = _sellTax;
    }
 
    function showSwapTaxes() public view returns (
        uint16 liquidityTax,
        uint16 marketingTax,
        uint16 operationsTax
    ) {
        liquidityTax = _liquidityTax;
        marketingTax = _marketingTax;
        operationsTax = _operationsTax;
    }
 
    function isSwapEnabled() public view returns (bool) {
        return _swapEnabled;
    }
 
    function showSwapTokenThreshold() public view returns (uint256) {
        return _swapTokenThreshold;
    }
 
    function isExcludedFromFees(
        address wallet
    ) public view returns (bool) {
        return _excludedFromFees[wallet];
    }
 
    // END OF GETTERS \\
 
    function transfer(
        address recipient, 
        uint256 amount
    ) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) external override returns (bool) {
        uint256 allowance_ = _allowances[sender][msg.sender];
        _transfer(sender, recipient, amount);
        require(allowance_ >= amount);
        _approve(sender, msg.sender, allowance_ - amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function _approve(
        address owner, 
        address spender, 
        uint256 amount
    ) private {
        require((owner != address(0) && spender != address(0)), "Owner/Spender address cannot be 0.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function approve(
        address spender, 
        uint256 amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function allowance(
        address owner_,
        address spender
    ) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }
    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balances[account];
    }
    function name() external pure returns (string memory) {
        return _tokenName;
    }
    function symbol() external pure returns (string memory) {
        return _tokenSymbol;
    }
    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }
    function decimals() external pure returns (uint8) {
        return _decimals;
    }
    function getOwner() external view returns (address) {
        return owner();
    }
    receive() external payable  {}
 
}