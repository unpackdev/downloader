/* The first ever PEPE ETF, yes you heard that right. 
https://t.me/ThePepeETF
*/

pragma solidity 0.8.19;

// SPDX-License-Identifier: Unlicensed

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    address _token;
    PepeETF TokenContract;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 24 hours;
    uint256 public minDistribution = 1 * (10 ** 19);

    uint256 public minBalanceForDividends = 0;

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor() {
        _token = msg.sender;
        TokenContract = PepeETF(payable(msg.sender));
    }

    function setDistributionCriteria(
        uint256 newMinPeriod,
        uint256 newMinDistribution
    ) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    }

    function setMinBalanceForDividends(uint256 amount) external onlyToken {
        minBalanceForDividends = amount;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (
            amount >= minBalanceForDividends && shares[shareholder].amount == 0
        ) {
            addShareholder(shareholder);
        } else if (
            amount <= minBalanceForDividends && shares[shareholder].amount > 0
        ) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        if (amount >= minBalanceForDividends) {
            shares[shareholder].amount = amount;
        } else {
            shares[shareholder].amount = 0;
        }
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external payable override onlyToken {
        totalDividends = totalDividends.add(msg.value);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares)
        );
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(
        address shareholder
    ) internal view returns (bool) {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            // RewardToken.transfer(shareholder, amount);
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend(address shareholder) external onlyToken {
        require(
            shareholderClaims[shareholder] + minPeriod < block.timestamp,
            "Must wait 24 hours before claiming"
        );
        distributeDividend(shareholder);
    }

    function rescueDividends(uint256 amountPercentage) external onlyToken {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }

    function getUnpaidEarnings(
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

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(
        uint256 share
    ) internal view returns (uint256) {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not onlyOwner to perform an operation.
     */
    error OwnableUnonlyOwnerAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
            revert OwnableUnonlyOwnerAccount(_msgSender());
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

contract PepeETF is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "Pepe ETF";
    string constant _symbol = "PTF";
    uint8 constant _decimals = 18;

    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public lpFeeReceiver; 
    address public mktFeeReceiver;

    uint256 _totalSupply = 420690000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = (_totalSupply * 10) / 1000;
    uint256 public _walletMax = (_totalSupply * 10) / 1000;
    
    bool public restrictWhales = true;

    bool public tradingAllowed = false;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public feeWL;
    mapping(address => bool) public txLmtWL;
    mapping(address => bool) public devidendWL;

    bool public takeFeeOnBuy = true;
    bool public takeFeeOnSell = true;
    bool public takeFeeOnTransfer = true;

    uint256 public lpFee = 0;
    uint256 public mktFee = 290;
    uint256 public rwdsFee = 10;

    uint256 public feeOnBuys = 0;
    uint256 public feeOnSells = 0;

    IDEXRouter public router;
    address public pair;
    mapping(address => bool) public isPair;

    DividendDistributor public dividendDistributor;
    uint256 distributorGas = 0;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    uint256 public swapThreshold = (_totalSupply * 3) / 2000;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountToken);

    constructor() {
        lpFeeReceiver = 0x774D7425A8F866D5D6056F8C555f0524fa8EF59C;
        mktFeeReceiver = 0x774D7425A8F866D5D6056F8C555f0524fa8EF59C;

        router = IDEXRouter(routerAddress);
        address pair_weth = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        pair = pair_weth;
        isPair[pair] = true;

        _allowances[address(this)][address(router)] = type(uint256).max;

        dividendDistributor = new DividendDistributor();

        uint256 minBalanceForRewards = (_totalSupply * 5) / 1000;
        dividendDistributor.setMinBalanceForDividends(minBalanceForRewards);

        feeWL[msg.sender] = true;
        feeWL[address(this)] = true;

        txLmtWL[msg.sender] = true;
        txLmtWL[pair] = true;
        txLmtWL[pair_weth] = true;

        devidendWL[pair] = true;
        devidendWL[pair_weth] = true;
        devidendWL[msg.sender] = true;
        devidendWL[address(this)] = true;
        devidendWL[address(0xdead)] = true;
        devidendWL[address(0)] = true;

        feeOnBuys = lpFee.add(mktFee).add(rwdsFee);
        feeOnSells = feeOnBuys + 340;

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            _totalSupply.sub(balanceOf(address(0xdead))).sub(
                balanceOf(address(0))
            );
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
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function checkPendingDividends(
        address account
    ) external view returns (uint256) {
        return dividendDistributor.getUnpaidEarnings(account);
    }

    function claimDividend() external {
        dividendDistributor.claimDividend(msg.sender);
    }

    function setMinBalanceForDividends(uint256 amount) external onlyOwner {
        dividendDistributor.setMinBalanceForDividends(amount);
    }

    function openTrading() public onlyOwner {
        tradingAllowed = true;
    }

    function changeTakeFeeOnBuy(bool status) public onlyOwner {
        takeFeeOnBuy = status;
    }

    function changeTakeFeeOnSell(bool status) public onlyOwner {
        takeFeeOnSell = status;
    }

    function changeTakeFeeOnTransfer(bool status) public onlyOwner {
        takeFeeOnTransfer = status;
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= 5, "Wallet Limit needs to be at least 0.5%");
        _walletMax = (_totalSupply * newLimit) / 1000;
    }

    function setTxLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= 5, "Wallet Limit needs to be at least 0.5%");
        _maxTxAmount = (_totalSupply * newLimit) / 1000;
    }

    function changeFees(
        uint256 newLiqFeeThou,
        uint256 newRewardFeeThou,
        uint256 newmktFee,
        uint256 extraSellFee
    ) external onlyOwner {
        lpFee = newLiqFeeThou;
        rwdsFee = newRewardFeeThou;
        mktFee = newmktFee;

        feeOnBuys = lpFee.add(mktFee).add(rwdsFee);
        feeOnSells = feeOnBuys + extraSellFee;
    }

    function changeSwapBackSettings(
        bool enableSwapBack,
        uint256 newSwapBackLimit,
        bool swapByLimitOnly
    ) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
        swapAndLiquifyByLimitOnly = swapByLimitOnly;
    }

    function changeDistributionCriteria(
        uint256 newinPeriod,
        uint256 newMinDistribution
    ) external onlyOwner {
        dividendDistributor.setDistributionCriteria(
            newinPeriod,
            newMinDistribution
        );
    }

    function changeDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function processDividends(uint256 gas) external onlyOwner {
        dividendDistributor.process(gas);
    }

    function setRouterAddress(address newRouter) public onlyOwner {
        IDEXRouter _uniswapV2Router = IDEXRouter(newRouter);
        // Create a uniswap pair for this new token
        IDEXFactory _uniswapV2Factory = IDEXFactory(_uniswapV2Router.factory());
        address pairAddress = _uniswapV2Factory.getPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        if (pairAddress == address(0)) {
            pairAddress = _uniswapV2Factory.createPair(
                address(this),
                _uniswapV2Router.WETH()
            );
        }
        isPair[pairAddress] = true;
        devidendWL[pairAddress] = true;
        txLmtWL[pairAddress] = true;

        router = _uniswapV2Router;
    }

    function changePair(address _address, bool status) public onlyOwner {
        isPair[_address] = status;
    }

    function changeIsFeeExempt(address holder, bool exempt) public onlyOwner {
        feeWL[holder] = exempt;
    }

    function changeIsTxLimitExempt(
        address holder,
        bool exempt
    ) public onlyOwner {
        txLmtWL[holder] = exempt;
    }

    function changeIsDividendExempt(
        address holder,
        bool exempt
    ) public onlyOwner {
        if (isPair[holder]) {
            exempt = true;
        }

        devidendWL[holder] = exempt;

        if (exempt) {
            dividendDistributor.setShare(holder, 0);
        } else {
            dividendDistributor.setShare(holder, _balances[holder]);
        }
    }

    function addDapp(address target) public onlyOwner {
        changeIsDividendExempt(target, true);
        changeIsTxLimitExempt(target, true);
        changeIsFeeExempt(target, true);
    }

    function changeFeeReceivers(
        address newLiquidityReceiver,
        address newMarketingWallet
    ) external onlyOwner {
        lpFeeReceiver = newLiquidityReceiver;
        mktFeeReceiver = newMarketingWallet;
    }

    function removeERC20(
        address tokenAddress,
        uint256 tokens
    ) public onlyOwner returns (bool success) {
        require(tokenAddress != address(this), "Cant remove the native token");
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function removeEther(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }

    function ManualSwap() external onlyOwner {
        swapBack();
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || txLmtWL[sender],
            "TX Limit Exceeded"
        );
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
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (!feeWL[sender]) {
            require(tradingAllowed, "Trading not open yet");
        }
        require(
            amount <= _maxTxAmount || txLmtWL[sender],
            "TX Limit Exceeded"
        );

        if (
            !isPair[sender] &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            swapBack();
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        if (!txLmtWL[recipient] && restrictWhales) {
            require(_balances[recipient].add(amount) <= _walletMax);
        }

        uint256 finalAmount = !feeWL[sender] && !feeWL[recipient]
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        // Dividend tracker
        if (!devidendWL[sender]) {
            try
                dividendDistributor.setShare(sender, _balances[sender])
            {} catch {}
        }

        if (!devidendWL[recipient]) {
            try
                dividendDistributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try dividendDistributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, finalAmount);

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeApplicable = 0;

        if (isPair[recipient] && takeFeeOnSell) {
            feeApplicable = feeOnSells;
        }
        if (isPair[sender] && takeFeeOnBuy) {
            feeApplicable = feeOnBuys;
        }
        if (!isPair[sender] && !isPair[recipient]) {
            if (takeFeeOnTransfer) {
                feeApplicable = feeOnSells;
            } else {
                feeApplicable = 0;
            }
        }

        uint256 feeAmount = amount.mul(feeApplicable).div(1000);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapBack() internal lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify
            .mul(lpFee)
            .div(feeOnBuys)
            .div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 totalETHFee = feeOnBuys.sub(lpFee.div(2));

        uint256 amountETHLiquidity = amountETH
            .mul(lpFee)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHReflection = amountETH.mul(rwdsFee).div(
            totalETHFee
        );
        uint256 amountETHMarketing = amountETH.mul(mktFee).div(
            totalETHFee
        );

        try
            dividendDistributor.deposit{value: amountETHReflection}()
        {} catch {}

        (bool tmpSuccess, ) = payable(mktFeeReceiver).call{
            value: amountETHMarketing,
            gas: 30000
        }("");

        tmpSuccess = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                lpFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }
}