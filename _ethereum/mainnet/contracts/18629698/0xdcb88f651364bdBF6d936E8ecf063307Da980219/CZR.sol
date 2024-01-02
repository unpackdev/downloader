// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.23;

// Telegram: https://t.me/CZRCommunityERC20

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract DividendDistributor {
    address public _token;
    address public immutable dividendToken;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalClaimed;
    }

    address[] private shareholders;
    mapping(address => uint256) private shareholderIndexes;
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalClaimed;
    uint256 public dividendsPerShare;
    uint256 private accuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _dividendToken) {
        _token = msg.sender;
        dividendToken = _dividendToken;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if (shares[shareholder].amount != 0) {
            distributeDividend(shareholder);
        }

        if (amount != 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount != 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(amount);
    }

    function deposit(uint256 amount) external onlyToken {
        if (amount != 0) {
            totalDividends += amount;
            dividendsPerShare += (accuracyFactor * amount) / totalShares;
        }
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getClaimableDividendOf(shareholder);
        if (amount != 0) {
            totalClaimed += amount;
            shares[shareholder].totalClaimed += amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
            IERC20(dividendToken).transfer(shareholder, amount);
        }
    }

    function claimDividend(address shareholder) external onlyToken {
        distributeDividend(shareholder);
    }

    function getClaimableDividendOf(
        address shareholder
    ) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(
        uint256 share
    ) internal view returns (uint256) {
        return (share * dividendsPerShare) / accuracyFactor;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function getDividendsClaimedOf(
        address shareholder
    ) external view returns (uint256) {
        require(shares[shareholder].amount != 0, "Not a shareholder!");
        return shares[shareholder].totalClaimed;
    }
}

contract CZR is IERC20, Owned {
    IDEXRouter private constant router =
        IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap Router
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = address(0);
    address private immutable WETH;
    address public immutable dividendToken; 

    string private constant _name = "Changpeng Zhao Reflect";
    string private constant _symbol = "CZR";
    uint8 private constant _decimals = 18;

    uint256 private _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public swapThreshold;
    
    uint256 public buyTax = 30;
    uint256 public sellTax = 30;

    uint256 public swapRewardPercent = 10;
    address public marketingWallet;

    bool public limit = true;
    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isBot;

    DividendDistributor public distributor;
    address public pair;

    bool public tradingOpen;
    bool public blacklistEnabled;
    bool private inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address _owner,
        address _marketingWallet,
        address _dividendToken
    ) Owned(_owner) {
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _allowances[address(this)][address(router)] = type(uint256).max;

        dividendToken = _dividendToken;
        distributor = new DividendDistributor(_dividendToken);
        marketingWallet = _marketingWallet;

        isFeeExempt[_owner] = true;
        isFeeExempt[_marketingWallet] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        swapThreshold = _totalSupply * 1 / 10000; // 0.01%
        maxTxAmount = (_totalSupply * 1) / 100; // 1%
        maxWalletAmount = (_totalSupply * 2) / 100; // 2%

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);

    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = currentAllowance - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            tradingOpen || sender == owner || recipient == owner,
            "Trading not yet enabled"
        ); //transfers disabled before openTrading

        if (blacklistEnabled) {
            require(!isBot[sender] && !isBot[recipient], "Bot");
        }

        if (limit) {
            if (sender != owner && recipient != owner)
                require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 contractTokenBal = balanceOf(address(this));
        bool overMinTokenBal = contractTokenBal >= swapThreshold;

        if (
            overMinTokenBal &&
            recipient == pair &&
            balanceOf(address(this)) != 0
        ) {
            swapBack();
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insufficient Balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;

        _balances[recipient] += amountReceived;

        if (sender != pair && !isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (recipient != pair && !isDividendExempt[recipient]) {
            try
                distributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insufficient Balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
            _balances[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {
        return (!(isFeeExempt[sender] || isFeeExempt[recipient]) &&
            (sender == pair || recipient == pair));
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount;

        if (recipient == pair) {
            feeAmount = (amount * sellTax) / 100;
        } else {
            feeAmount = (amount * buyTax) / 100;
        }

        _balances[address(this)] += feeAmount;

        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function swapBack() internal swapping {
        uint256 tokenBal = balanceOf(address(this));
        uint256 tokenForDividends = (tokenBal * swapRewardPercent) / 100;

        if (tokenForDividends != 0) {
            uint256 balBefore = IERC20(dividendToken).balanceOf(address(distributor));
            swapTokensForDividend(tokenForDividends, address(distributor));
            uint256 balAfter = IERC20(dividendToken).balanceOf(address(distributor));
            distributor.deposit(balAfter - balBefore);
        }

        if (tokenBal - tokenForDividends != 0) {
            swapTokensForETH(tokenBal - tokenForDividends, marketingWallet);
        }
    }

    function swapTokensForDividend(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = WETH;
        path[2] = dividendToken;

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }

    function getClaimableDividendOf(
        address shareholder
    ) public view returns (uint256) {
        return distributor.getClaimableDividendOf(shareholder);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function getTotalDividends() external view returns (uint256) {
        return distributor.totalDividends();
    }

    function getTotalClaimed() external view returns (uint256) {
        return distributor.totalClaimed();
    }

    function getDividendsClaimedOf(
        address shareholder
    ) external view returns (uint256) {
        return distributor.getDividendsClaimedOf(shareholder);
    }

    function checkBot(address account) external view returns (bool) {
        return isBot[account];
    }

    function openTrading() external onlyOwner {
        tradingOpen = true;
    }

    function setBot(address _address, bool toggle) external onlyOwner {
        isBot[_address] = toggle;
        _setIsDividendExempt(_address, toggle);
    }

    function setIsDividendExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function manualSendToMarketingWallet() external onlyOwner {
        payable(marketingWallet).transfer(address(this).balance);
    }

    function claimDividendOf(address holder) external onlyOwner {
        distributor.claimDividend(holder);
    }

    function manualBurn(uint256 amount) external onlyOwner returns (bool) {
        return _basicTransfer(address(this), DEAD, amount);
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function removeLimit() external onlyOwner {
        limit = false;
    }

    function updateMaxTxAmount(uint256 _percen) external onlyOwner{
        maxTxAmount = _totalSupply * _percen / 100;
    }
    
    function updateMaxWalletAmount(uint256 _percen) external onlyOwner{
        maxWalletAmount = _totalSupply * _percen / 100;
    }

    function setBlacklistEnabled() external onlyOwner {
        require(blacklistEnabled == false, "can only be called once");
        blacklistEnabled = true;
    }

    function setSwapRewardPercent(uint256 percent) external onlyOwner {
        require(percent <= 100, "Can not exceed 100%");
        swapRewardPercent = percent;
    }

    function setSwapThreshold(uint256 amount) external onlyOwner {
        swapThreshold = amount;
    }

    // must be in percentage (less than 100)
    function setBuyTax(uint256 _tax) external onlyOwner{
        buyTax = _tax;
    }

    // must be in percentage (less than 100)
    function setSellTax(uint256 _tax) external onlyOwner{
        sellTax = _tax;
    }
}