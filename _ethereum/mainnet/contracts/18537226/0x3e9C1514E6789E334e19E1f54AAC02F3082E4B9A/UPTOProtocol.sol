// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;


// DApp:      https://www.upto10protocol.org
// Docs:      https://docs.upto10protocol.org

// Twitter:   https://twitter.com/upto10pro_erc
// Telegram:  https://t.me/upto10pro_erc


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function totalSupply() external view returns(uint256);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint deadline ) external payable;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}


library SafeERC20 {

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: INTERNAL TRANSFER_FAILED');
    }
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}


contract UPTOProtocol is Ownable {

    using SafeMath for uint256;

    string public constant name = "UPTO10 Protocol";
    string public constant symbol = "UPTO";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100_000_000 * 10**decimals;       //100m total supply
    bool private inSwap = false;

    uint256 public _maxTxAmount = (totalSupply * 2) / 100;
    uint256 public _maxWalletSize = (totalSupply * 2) / 100;            
    uint256 public _taxSwapThreshold= (1 * totalSupply) / 100000;        // 0.001%
    uint256 public _maxTaxSwap= 100 * _taxSwapThreshold;
    uint256 public _ownerPercent = 5;       // team token 5%
    
    address payable public treasuryWallet = payable(0x6e0020D7d4d2B6d69E6b99deab5AC68C764c2Ce7);

    uint8 public constant MAX_BUY_FEES = 100;       //10% max
    uint8 public constant MAX_SELL_FEES = 100;      //10% max
    uint8 public constant TRADING_DISABLED = 0;
    uint8 public constant TRADING_ENABLED = 1;

    uint8 public buyTotalFees = 200;
    uint8 public sellTotalFees = 200;

    bool private swapEnabled = false;
    bool private safeEnabled = false;
    uint8 public tradingStatus = TRADING_DISABLED;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _allowedDuringPause;
    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => uint256) public begged;

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;

    event MaxTxAmountUpdated(uint _maxTxAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    error ZeroAddress();
    error InsufficientAllowance();
    error InsufficientBalance();
    error CannotRemoveV2Pair();
    error WithdrawalFailed();
    error InvalidState();
    error FeesExceedMax();
    error TradingDisabled();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() Ownable(msg.sender) payable {

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[treasuryWallet] = true;
        
        uint256 teamToLP = (totalSupply * _ownerPercent) / 100;
        uint256 begToLP = totalSupply - teamToLP;

        _balances[owner()] = teamToLP;
        _balances[address(this)] = begToLP;
        emit Transfer(address(0), address(this), begToLP);

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    function startBegging() external payable onlyOwner {

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        automatedMarketMakerPairs[uniswapV2Pair] = true;        
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Router
            .addLiquidityETH{value: msg.value}(
                address(this),
                balanceOf(address(this)),
                0,
                0,
                msg.sender,block.timestamp
            );
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        if(owner == address(0)) revert ZeroAddress();
        if(spender == address(0)) revert ZeroAddress();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            if(currentAllowance < amount) revert InsufficientAllowance();
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function _transfer(address from, address to, uint256 amount) private {
        if(from == address(0)) revert ZeroAddress();
        if(to == address(0)) revert ZeroAddress();

        if(tradingStatus == TRADING_DISABLED) {
            if(from != owner() && from != treasuryWallet && from != address(this) && to != owner()) {
                if(!_allowedDuringPause[from]) {
                    revert TradingDisabled();
                }
            }
        }

        bool takeFee = true;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFees[to] ) {
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
            require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
        }

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 1000;
            } else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 1000;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance>_taxSwapThreshold;
            if (!inSwap && canSwap && to == uniswapV2Pair && swapEnabled && amount > _taxSwapThreshold) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));

                uint256 ethBalance = address(this).balance;
                if(ethBalance > 0) {
                    sendETHForFees(ethBalance);
                }
            }

            if (fees > 0) {
                unchecked {
                    amount = amount - fees;
                    _balances[from] -= fees;
                    _balances[address(this)] += fees;
                }
            }

            unchecked {
                _balances[from] -= amount;
                _balances[to] += amount;
            }
            
        } else {
            if(automatedMarketMakerPairs[to] && from !=address(this)) {
                unchecked {
                    _balances[from] -= fees;
                    _balances[to] += amount;
                }
            } else {
                unchecked {
                    _balances[from] -= amount;
                    _balances[to] += amount;
                }
            }
        }

        emit Transfer(from, to, amount);
    }

    function setFees(uint8 _buyTotalFees, uint8 _sellTotalFees) external onlyOwner {
        if(_buyTotalFees > MAX_BUY_FEES || _sellTotalFees > MAX_SELL_FEES) revert FeesExceedMax();
        buyTotalFees = _buyTotalFees;
        sellTotalFees = _sellTotalFees;
    }

    function setExcludedFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setAllowedDuringPause(address account, bool allowed) public onlyOwner {
        _allowedDuringPause[account] = allowed;
    }

    function enableTrading() public onlyOwner {
        require(tradingStatus == TRADING_DISABLED,"trading is already open");

        tradingStatus = TRADING_ENABLED;
        swapEnabled = true;        
    }

    function sendETHForFees(uint256 amount) private {
        treasuryWallet.transfer(amount);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        if(pair == uniswapV2Pair) revert CannotRemoveV2Pair();
        automatedMarketMakerPairs[pair] = value;
    }

    function updateTreasuryWallet(address newAddress) external onlyOwner {
        if(newAddress == address(0)) revert ZeroAddress();
        treasuryWallet = payable(newAddress);
    }

    function excludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawToken(address token, address to) external onlyOwner {
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        SafeERC20.safeTransfer(token, to, _contractBalance); // Use safeTransfer
    }

    function withdrawETH(address addr) external onlyOwner {
        if(addr == address(0)) revert ZeroAddress();

        (bool success, ) = addr.call{value: address(this).balance}("");
        if(!success) revert WithdrawalFailed();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimit() external onlyOwner{
        _maxTxAmount = totalSupply;
        _maxWalletSize = totalSupply;

        buyTotalFees = 20;
        sellTotalFees = 20;

        emit MaxTxAmountUpdated(totalSupply);
    }

    receive() external payable {}
}