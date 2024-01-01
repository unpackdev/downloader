// website  : https://tbet.finance
// twitter  : https://twitter.com/tbet_erc
// telegram : https://t.me/Tbet_erc
// docs     : https://docs.tbet.finance

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts/access/Ownable.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File contracts/IUniswap.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

interface IPair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function sync() external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapRouter {
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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity 0.8.21;

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
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
}

contract TBetFinance is ERC20Detailed, Ownable {
    uint256 public maxAmount;
    uint256 public maxWallet;

    address public marketingWallet;
    address public treasuryAdress;

    uint256 public marketingBuyFee = 2;
    uint256 public marketingSellFee = 2;

    uint256 public treasuryBuyFee = 1;
    uint256 public treasurySellFee = 3;

    uint256 public buyTax = marketingBuyFee + treasuryBuyFee;
    uint256 public sellTax = marketingSellFee + treasurySellFee;

    uint256 private _initialTax = 30;
    uint256 private _reduceTaxAt = 20;

    uint256 private _buyCount = 0;
    uint256 private _sellCount = 0;

    uint8 private constant DECIMALS = 18;
    event RemovedLimits();

    IUniswapRouter public router;
    address public pair;

    bool public limitsInEffect = true;
    bool public tradingEnable = false;

    uint256 private _totalSupply = 1_000_000_000 * 10**DECIMALS;

    uint256 private swapTokenAtAmount = _totalSupply / 200; // 0.5% of total supply

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowedTokens;
    mapping(address => bool) public isExcludedFromFees;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() ERC20Detailed("TBet Finance", "TBF", DECIMALS) {
        marketingWallet = 0x721d4c65921743bdc741E53310d68B0257413A05;
        treasuryAdress = 0x5566e17a58a7B399BE7E3564371452db91b3bcd6;

        router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _balances[msg.sender] = _totalSupply;

        maxAmount = (_totalSupply * 2) / 100;
        maxWallet = (_totalSupply * 2) / 100;

        pair = IFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[address(router)] = true;
        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[marketingWallet] = true;
        isExcludedFromFees[treasuryAdress] = true;

        _allowedTokens[address(this)][address(router)] = type(uint256).max;
        _allowedTokens[address(this)][address(this)] = type(uint256).max;
        _allowedTokens[address(msg.sender)][address(router)] = type(uint256)
            .max;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedTokens[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _balances[who];
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect, "Limits already removed");
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function excludedFromFees(address _address, bool _value)
        external
        onlyOwner
    {
        isExcludedFromFees[_address] = _value;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (
            !inSwap &&
            !isExcludedFromFees[sender] &&
            !isExcludedFromFees[recipient]
        ) {
            require(tradingEnable, "Trading not live");
            if (limitsInEffect) {
                if (sender == pair || recipient == pair) {
                    require(amount <= maxAmount, "Max Tx Exceeded");
                }
                if (recipient != pair) {
                    require(
                        balanceOf(recipient) + amount <= maxWallet,
                        "Max Wallet Exceeded"
                    );
                }
            }

            if (recipient == pair) {
                if (balanceOf(address(this)) >= swapTokenAtAmount) {
                    swapBack();
                }
            }

            if (sender == pair) {
                _buyCount += 1;

                uint256 taxAmount = (amount *
                    (_buyCount > _reduceTaxAt ? buyTax : _initialTax)) / 100;

                uint256 amountToTreasury = (taxAmount * treasuryBuyFee) /
                    (buyTax);
                uint256 amountToMarketing = taxAmount - amountToTreasury;

                _balances[sender] -= taxAmount;
                _balances[address(this)] += amountToMarketing;
                _balances[treasuryAdress] += amountToTreasury;

                emit Transfer(sender, address(this), amountToMarketing);
                emit Transfer(sender, treasuryAdress, amountToTreasury);

                amount -= taxAmount;
            } else if (recipient == pair) {
                _sellCount += 1;

                uint256 taxAmount = (amount *
                    (_sellCount > _reduceTaxAt ? sellTax : _initialTax)) / 100;

                uint256 amountToTreasury = (taxAmount * treasurySellFee) /
                    (sellTax);
                uint256 amountToMarketing = taxAmount - amountToTreasury;

                _balances[sender] -= taxAmount;
                _balances[address(this)] += amountToMarketing;
                _balances[treasuryAdress] += amountToTreasury;

                emit Transfer(sender, address(this), amountToMarketing);
                emit Transfer(sender, treasuryAdress, amountToTreasury);

                amount -= taxAmount;
            }
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedTokens[from][msg.sender] != type(uint256).max) {
            require(
                _allowedTokens[from][msg.sender] >= value,
                "Insufficient Allowance"
            );
            _allowedTokens[from][msg.sender] =
                _allowedTokens[from][msg.sender] -
                (value);
        }
        _transferFrom(from, to, value);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedTokens[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedTokens[msg.sender][spender] = 0;
        } else {
            _allowedTokens[msg.sender][spender] = oldValue - (subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedTokens[msg.sender][spender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedTokens[msg.sender][spender] =
            _allowedTokens[msg.sender][spender] +
            (addedValue);
        emit Approval(msg.sender, spender, _allowedTokens[msg.sender][spender]);
        return true;
    }

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _allowedTokens[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnable, "Trading Live Already");
        tradingEnable = true;
    }

    function swapBack() public swapping {
        uint256 amountToSwap = balanceOf(address(this));
        if (amountToSwap == 0) {
            return;
        }

        if (amountToSwap > swapTokenAtAmount) {
            amountToSwap = swapTokenAtAmount;
        }

        _swapTokensForETH(amountToSwap);

        if (address(this).balance > 0) {
            (bool success, ) = payable(marketingWallet).call{
                value: address(this).balance
            }("");
            require(success, "Failed to send ETH to marketing wallet");
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            payable(marketingWallet),
            block.timestamp
        );
    }

    receive() external payable {}
}