// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Pray, a blessed token, graciously bestows rewards in the divine currency of $JESUS to its faithful holders

// https://praytoken.xyz/
// https://t.me/prayportal
// https://twitter.com/praytoken

import "./IERC20.sol";
import "./Ownable.sol";

contract DividendDistributor {
    address public _token;
    address public _owner;

    address public immutable BASE_TOKEN;

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
    uint256 private dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    // constructor
    constructor(address owner, address baseToken_) {
        _token = msg.sender;
        _owner = owner;
        BASE_TOKEN = baseToken_;
    }

    receive() external payable {}

    // token
    function setShare(address shareholder, uint256 amount) external onlyToken {
        if (shares[shareholder].amount > 0) {
            _distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            _addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            _removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = _getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit(uint256 amount) external onlyToken {
        if (amount > 0) {
            totalDividends = totalDividends + amount;
            dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * amount / totalShares);
        }
    }

    function claimDividend(address shareholder) external onlyToken {
        _distributeDividend(shareholder);
    }

    // owners
    function manualSend(uint256 amount, address holder) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }

    // views
    function getDividendsClaimedOf(address shareholder) external view returns (uint256) {
        require(shares[shareholder].amount > 0, "You're not a shareholder");
        return shares[shareholder].totalClaimed;
    }

    function getClaimableDividendOf(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) return 0;

        uint256 shareholderTotalDividends = _getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) return 0;

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    // internal
    function _getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }

    function _addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function _removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function _distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) return;

        uint256 amount = getClaimableDividendOf(shareholder);
        if (amount > 0) {
            totalClaimed = totalClaimed + amount;
            shares[shareholder].totalClaimed = shares[shareholder].totalClaimed + amount;
            shares[shareholder].totalExcluded = _getCumulativeDividends(shares[shareholder].amount);
            IERC20(BASE_TOKEN).transfer(shareholder, amount);
        }
    }
}

error ThresholdExceedOnePercent();
error FeeExceedMaxFee();
error BotNotAllowed();
error ExceedMaxBuy();
error AlreadyLaunched();
error ZeroValue();
error ZeroToken();

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Pray is IERC20, Ownable {
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable JESUS = address(0xba386A4Ca26B85FD057ab1Ef86e3DC7BdeB5ce70);
    DividendDistributor private immutable DISTRIBUTOR;

    string private constant NAME = "Jesus Printer";
    string private constant SYMBOL = "PRAY";

    uint256 public constant MAX_SUPPLY = 777_777_777_777 ether;
    uint256 public constant MAX_FEE = 20;
    uint256 public constant FEE_LOWER_BLOCK = 8;

    address public uniswapPair;
    address payable public marketingWallet = payable(0x495f20D7Df67e65D821998E91dD2393b2bFC54c6);
    address payable public devWallet = payable(0x495f20D7Df67e65D821998E91dD2393b2bFC54c6);

    struct Fee {
        uint8 reflection;
        uint8 marketing;
        uint128 total;
    }

    uint128 private constant INITIAL_TOTAL_FEE = 20;
    Fee public fee = Fee({reflection: 3, marketing: 2, total: 5});
    uint256 public maxBuy = MAX_SUPPLY * 2 / 100;
    uint256 public threshold = MAX_SUPPLY * 5 / 1000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isBot;

    uint256 public launchedAt;
    bool public buyLimitEnabled = true;

    bool public blacklistEnabled = true;
    bool private inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _allowances[address(this)][address(UNISWAP_V2_ROUTER)] = type(uint256).max;

        DISTRIBUTOR = new DividendDistributor(tx.origin, JESUS);

        isFeeExempt[tx.origin] = true;
        isFeeExempt[marketingWallet] = true;

        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        _balances[tx.origin] = MAX_SUPPLY;

        emit Transfer(address(0), tx.origin, MAX_SUPPLY);
    }

    receive() external payable {}

    function claimDividend() external {
        DISTRIBUTOR.claimDividend(msg.sender);
    }

    struct Airdrop {
        uint256 amount;
        address addr;
    }

    function airdrop(Airdrop[] calldata airdrops) external {
        for (uint256 i = 0; i < airdrops.length; i++) {
            _transferFrom(msg.sender, airdrops[i].addr, airdrops[i].amount);
        }
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(sender, recipient, amount);
    }

    function totalSupply() external pure override returns (uint256) {
        return MAX_SUPPLY;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function checkBot(address account) public view returns (bool) {
        return isBot[account];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return MAX_SUPPLY - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function getTotalDividends() external view returns (uint256) {
        return DISTRIBUTOR.totalDividends();
    }

    function getTotalClaimed() external view returns (uint256) {
        return DISTRIBUTOR.totalClaimed();
    }

    function getDividendsClaimedOf(address shareholder) external view returns (uint256) {
        return DISTRIBUTOR.getDividendsClaimedOf(shareholder);
    }

    function getClaimableDividendOf(address shareholder) public view returns (uint256) {
        return DISTRIBUTOR.getClaimableDividendOf(shareholder);
    }

    function launch(uint256 tokenAmount_) external payable onlyOwner {
        if (uniswapPair != address(0)) revert AlreadyLaunched();
        if (msg.value == 0) revert ZeroValue();
        if (tokenAmount_ == 0) revert ZeroToken();
        _basicTransfer(msg.sender, address(this), tokenAmount_);
        IUniswapV2Router02 router = UNISWAP_V2_ROUTER;
        address _pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        isDividendExempt[_pair] = true;

        _approve(address(this), address(router), type(uint256).max);
        _approve(address(this), address(_pair), type(uint256).max);
        IERC20(_pair).approve(address(router), type(uint256).max);

        router.addLiquidityETH{value: address(this).balance}(
            address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp
        );
        uniswapPair = _pair;
        launchedAt = block.number;
    }

    function removeBuyLimit() external onlyOwner {
        buyLimitEnabled = false;
    }

    function setBlacklistEnabled(bool b_) external onlyOwner {
        blacklistEnabled = b_;
    }

    function setSwapThresholdAmount(uint256 amount) external onlyOwner {
        if (amount > MAX_SUPPLY / 100) revert ThresholdExceedOnePercent();
        threshold = amount;
    }

    function setMarketingWallet(address w_) external onlyOwner {
        marketingWallet = payable(w_);
    }

    function manualBurn(uint256 amount) external onlyOwner returns (bool) {
        return _basicTransfer(address(this), DEAD, amount);
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setFee(uint8 reflectionFee, uint8 marketingFee) external onlyOwner {
    uint128 __totalFee = reflectionFee + marketingFee;
    if (__totalFee > MAX_FEE) revert FeeExceedMaxFee();
    fee = Fee({reflection: reflectionFee, marketing: marketingFee, total: __totalFee});
    }

    function setBot(address _address, bool toggle) external onlyOwner {
        isBot[_address] = toggle;
        _setIsDividendExempt(_address, toggle);
    }

    function setMaxBuy(uint256 _maxBuy) external onlyOwner {
        maxBuy = _maxBuy;
    }

    function manualSend() external onlyOwner {
        (bool success,) = payable(marketingWallet).call{value: address(this).balance}("");
        require(success);
    }

    function ownerClaimDividend(address holder) external onlyOwner {
        DISTRIBUTOR.claimDividend(holder);
    }

    function clearStuckToken() external {
        _transferFrom(address(this), devWallet, balanceOf(address(this)));
    }

    function clearStuckToken(address token) external {
        IERC20(token).transfer(devWallet, IERC20(token).balanceOf(address(this)));
    }

    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != uniswapPair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            DISTRIBUTOR.setShare(holder, 0);
        } else {
            DISTRIBUTOR.setShare(holder, _balances[holder]);
        }
    }

    function _swapTokensForBaseToken(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();
        path[2] = JESUS;

        // make the swap
        UNISWAP_V2_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap UNISWAP_V2_PAIR path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();

        // make the swap
        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapBack() internal swapping {
        uint256 amountToSwap = balanceOf(address(this));
        Fee memory _fee = fee;

        uint256 amountMarketingETH = amountToSwap * _fee.marketing / _fee.total;
        _swapTokensForEth(amountMarketingETH);
        _swapTokensForBaseToken(amountToSwap * _fee.reflection / _fee.total);

        // reflection
        uint256 dividends = IERC20(JESUS).balanceOf(address(this));
        bool success = IERC20(JESUS).transfer(address(DISTRIBUTOR), dividends);

        if (success) {
            DISTRIBUTOR.deposit(dividends);
        }

        // marketing
        payable(marketingWallet).call{value: address(this).balance}("");
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        address __owner = owner();
        address __uniswapPair = uniswapPair;
        if (blacklistEnabled) {
            if (isBot[sender] || isBot[recipient]) revert BotNotAllowed();
        }
        if (buyLimitEnabled && !inSwap && __uniswapPair != address(0) && sender == __uniswapPair) {
            if (sender != __owner && recipient != __owner && amount > maxBuy) revert ExceedMaxBuy();
        }

        if (inSwap) return _basicTransfer(sender, recipient, amount);

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= threshold;

        bool shouldSwapBack = (overMinTokenBalance && recipient == __uniswapPair && balanceOf(address(this)) > 0);
        if (shouldSwapBack) _swapBack();

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = _shouldTakeFee(sender, recipient) ? _takeFee(sender, amount) : amount;

        _balances[recipient] = _balances[recipient] + amountReceived;

        if (sender != __uniswapPair && !isDividendExempt[sender]) {
            try DISTRIBUTOR.setShare(sender, _balances[sender]) {} catch {}
        }
        if (recipient != __uniswapPair && !isDividendExempt[recipient]) {
            try DISTRIBUTOR.setShare(recipient, _balances[recipient]) {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        address __uniswapPair = uniswapPair;
        return (
            !(isFeeExempt[sender] || isFeeExempt[recipient]) && (sender == __uniswapPair || recipient == __uniswapPair)
        );
    }

    function _takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;
        uint128 _feeTotal = block.number > launchedAt + FEE_LOWER_BLOCK ? fee.total : INITIAL_TOTAL_FEE;
        feeAmount = amount * _feeTotal / 100;
        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function _approve(address add, address spender, uint256 amount) internal {
        _allowances[add][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }
}
