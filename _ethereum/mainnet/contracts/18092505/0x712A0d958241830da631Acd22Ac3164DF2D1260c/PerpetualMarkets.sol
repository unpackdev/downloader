/**

Twitter : https://twitter.com/Perp_Markets

Telegram : https://t.me/PerpetualMarkets
 
Website : https://www.perpetualmarkets.tech/

 */

pragma solidity ^0.8.0;

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


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);


    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address to, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

 
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

 
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}


    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}



//SPDX-License-Identifier: MIT

/**

Twitter : https://twitter.com/Perp_Markets

Telegram : https://t.me/PerpetualMarkets
 
Website : https://www.perpetualmarkets.tech/

 */




pragma solidity 0.8.19;

interface DexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract PerpetualMarkets is ERC20, Ownable {
    struct Tax {
        uint256 marketingTax;
    }

    uint256 private constant _totalSupply = 1_000_000 * 1e18;

    //Router
    DexRouter public immutable uniswapRouter;
    address public immutable pairAddress;

    //Taxes
    Tax public buyTaxes = Tax(10);
    Tax public sellTaxes = Tax(10);
    Tax public transferTaxes = Tax(0);



    //Whitelisting from taxes/maxwallet/txlimit/etc
    mapping(address => bool) private whitelisted;

    //Swapping
    uint256 public swapTokensAtAmount = _totalSupply / 1_000; //after 0.1% of total supply, swap them
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;
    bool public tradingEnabled = false;
    uint256 public startTradingBlock;

    //Wallets
    address public marketingWallet = 0x7A34c165c105378F6F25cACb60eC4750420bE1d7 ;
    uint256 public maxWalletPercentage = 2;


    //Events
    event BuyFeesUpdated(uint256 indexed _trFee);
    event SellFeesUpdated(uint256 indexed _trFee);
    event marketingWalletChanged(address indexed _trWallet);
    event SwapThresholdUpdated(uint256 indexed _newThreshold);
    event InternalSwapStatusUpdated(bool indexed _status);
    event Whitelist(address indexed _target, bool indexed _status);
    event MaxWalletChanged(uint256 percentage);

    constructor() ERC20("Perpetual Markets", "PM") {

        uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // mainet
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;       
        _mint(msg.sender, _totalSupply);


    }

    function setmarketingWallet(address _newmarketing) external onlyOwner {
        require(
            _newmarketing != address(0),
            "can not set marketing to dead wallet"
        );
        marketingWallet = _newmarketing;
        emit marketingWalletChanged(_newmarketing);
    }
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        startTradingBlock = block.number;
    }

    function setBuyTaxes(uint256 _marketingTax) external onlyOwner {
        buyTaxes.marketingTax = _marketingTax;
        require(_marketingTax <= 30, "Can not set buy fees higher than 30%");
        emit BuyFeesUpdated(_marketingTax);
    }

    function setSellTaxes(uint256 _marketingTax) external onlyOwner {
        sellTaxes.marketingTax = _marketingTax;
        require(_marketingTax <= 30, "Can not set buy fees higher than 30%");
        emit SellFeesUpdated(_marketingTax);
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(
            _newAmount > 0 && _newAmount <= (_totalSupply * 5) / 1000,
            "Minimum swap amount must be greater than 0 and less than 0.5% of total supply!"
        );
        swapTokensAtAmount = _newAmount;
        emit SwapThresholdUpdated(swapTokensAtAmount);
    }

    function toggleSwapping() external onlyOwner {
        swapAndLiquifyEnabled = (swapAndLiquifyEnabled) ? false : true;
    }

    function setWhitelistStatus(
        address _wallet,
        bool _status
    ) external onlyOwner {
        whitelisted[_wallet] = _status;
        emit Whitelist(_wallet, _status);
    }

    function checkWhitelist(address _wallet) external view returns (bool) {
        return whitelisted[_wallet];
    }
    function setMaxWalletPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage > 1, "Percentage must be greater than 1%");
    require(_percentage <= 100, "Percentage must be less than or equal to 100");
    maxWalletPercentage = _percentage;
    emit MaxWalletChanged(_percentage);
}


    // this function is reponsible for managing tax, if _from or _to is whitelisted, we simply return _amount and skip all the limitations
function _takeTax(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (whitelisted[_from] || whitelisted[_to]) {
            return _amount;
        }

        uint256 totalTax = transferTaxes.marketingTax;

        if (_to == pairAddress) {
            totalTax = sellTaxes.marketingTax;
        } else if (_from == pairAddress) {
            totalTax = buyTaxes.marketingTax;
        }

        // Check if within the first 5 blocks
if (block.number <= startTradingBlock + 5) {
    if (block.number == startTradingBlock + 4) {
        totalTax = 10;
    } else if (block.number == startTradingBlock + 3) {
        totalTax = 10;
    } else if (block.number == startTradingBlock + 2) {
        totalTax = 15;
    } else if (block.number == startTradingBlock + 1) {
        totalTax = 20;
    } else if (block.number == startTradingBlock ) {
        totalTax = 25;
    } else {
        totalTax = 10;
    }
}

        uint256 tax = 0;
        if (totalTax > 0) {
            tax = (_amount * totalTax) / 100;
            super._transfer(_from, address(this), tax);
        }
        return (_amount - tax);
    }

function _transfer(
    address _from,
    address _to,
    uint256 _amount
) internal virtual override {
    require(_from != address(0), "transfer from address zero");
    require(_to != address(0), "transfer to address zero");
    require(_amount > 0, "Transfer amount must be greater than zero");

    // Calculate the maximum wallet amount based on the total supply and the maximum wallet percentage
    uint256 maxWalletAmount = _totalSupply * maxWalletPercentage / 100;

    // Check if the transaction is within the maximum wallet limit
    if (!whitelisted[_from] && !whitelisted[_to] && _to != address(0) && _to != address(this) && _to != pairAddress) {
        require(balanceOf(_to) + _amount <= maxWalletAmount, "Exceeds maximum wallet amount");
    }

    uint256 toTransfer = _takeTax(_from, _to, _amount);

    bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
    if (!whitelisted[_from] && !whitelisted[_to]) {
        require(tradingEnabled, "Trading not active");
        if (pairAddress == _to && swapAndLiquifyEnabled && canSwap && !isSwapping) {
            internalSwap();
        }
    }
    super._transfer(_from, _to, toTransfer);
}

    function internalSwap() internal {
        isSwapping = true;
        uint256 taxAmount = balanceOf(address(this)); 
        if (taxAmount == 0) {
            return;
        }
        swapToETH(balanceOf(address(this)));
       (bool success, ) = marketingWallet.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
        isSwapping = false;
    }

    function swapToETH(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), _amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}
}