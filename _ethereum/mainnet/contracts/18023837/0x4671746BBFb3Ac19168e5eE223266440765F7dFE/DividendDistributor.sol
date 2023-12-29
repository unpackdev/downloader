/*
AUDINALS
Website: https://www.audinals.io/
Telegram: https://t.me/audinalsofficial
Twitter: https://twitter.com/audinalsmusic
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event. C U ON THE MOON
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if(currentAllowance != type(uint256).max) { 
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _initialTransfer(address to, uint256 amount) internal virtual {
        _balances[to] = amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface USDT {
    function balanceOf(address who) external returns (uint);
    function transfer(address to, uint value) external;
    function approve(address spender, uint value) external;
}

interface IDividendDistributor {
    function initialize() external;
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _claimAfter) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimDividend(address shareholder) external;
    function getUnpaidEarnings(address shareholder) external view returns (uint256);
    function getPaidDividends(address shareholder) external view returns (uint256);
    function getTotalPaid() external view returns (uint256);
    function getClaimTime(address shareholder) external view returns (uint256);
    function getLostRewards(address shareholder) external view returns (uint256);
    function getTotalDividends() external view returns (uint256);
    function getTotalDistributed() external view returns (uint256);
    function getTotalSacrificed() external view returns (uint256);
    function countShareholders() external view returns (uint256);
    function migrate(address newDistributor) external;
}

contract DividendDistributor is IDividendDistributor, Ownable {

    address public _token;
    USDT public reward = USDT(0xdAC17F958D2ee523a2206206994597C13D831ec7); //USDT

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] public shareholders;
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;
    mapping (address => uint256) public shareholderBonus;
    mapping (address => uint256) public amountSacrificed;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public totalSacrificed;
    uint256 public totalReused;
    uint256 public totalBonus;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 5 days;
    uint256 public bonusPeriod = 2 days;
    uint256 public minDistribution = 1 * (10 ** 4);

    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IDexRouter dexRouter = IDexRouter(routerAddress);
    uint256 public slippage = 98;

    bool public initialized;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    
    function getTotalDividends() external view override returns (uint256) {
        return totalDividends;
    }
    function getTotalDistributed() external view override returns (uint256) {
        return totalDistributed;
    }
    function getTotalSacrificed() external view override returns (uint256) {
        return totalSacrificed;
    }

    constructor () {
        reward.approve(routerAddress, type(uint256).max);
    }
    
    function initialize() external override {
        initialized = true;
    }

    function setToken(address newToken) external onlyOwner {
        initialized = false;
        _token = newToken;
    }
    
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _claimAfter) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        _claimAfter;
    }

    function setBonusPeriod(uint256 _amount) external onlyOwner {
        bonusPeriod = _amount;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
            shares[shareholder].totalExcluded = getCumulativeDividends(amount);
            shareholderClaims[shareholder] = block.timestamp;
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
        
	    uint256 currentShare = shares[shareholder].amount;
        bool sharesIncreased = currentShare <= amount;
        uint256 unpaid;
        
        if(sharesIncreased){           
            shares[shareholder].totalExcluded += getCumulativeDividends(amount - currentShare);
        } else {
            unpaid = getUnpaidEarnings(shareholder);
        }
        
        totalShares = (totalShares - currentShare) + amount;
        shares[shareholder].amount = amount;
        
        if (!sharesIncreased) {
            if (reward.balanceOf(address(this)) < unpaid) unpaid = reward.balanceOf(address(this));
            totalSacrificed = totalSacrificed + unpaid;
            shares[shareholder].totalExcluded = getCumulativeDividends(amount);
            amountSacrificed[shareholder] += unpaid;
        }
    }

    function deposit() external payable override {
	    address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(reward);

        uint256 spend = address(this).balance;
        uint256[] memory amountsout = dexRouter.getAmountsOut(spend, path);

	    uint256 curBal = reward.balanceOf(address(this));

	    dexRouter.swapExactETHForTokens{value: spend}(
            amountsout[1] * slippage / 100,
            path,
            address(this),
            block.timestamp
        );

	    uint256 amount = reward.balanceOf(address(this)) - curBal;
        totalDividends += amount;
        if(totalShares > 0)
            if(dividendsPerShare == 0)
                dividendsPerShare = (dividendsPerShareAccuracyFactor * totalDividends) / totalShares;
            else
                dividendsPerShare += ((dividendsPerShareAccuracyFactor * amount) / totalShares);
    }

    function reinjectSacrificed(uint256 percent) external onlyOwner {
        uint256 amount = (totalSacrificed - totalReused) * percent / 100;
        totalDividends += amount;
        totalReused += amount;
        if(totalShares > 0)
            if(dividendsPerShare == 0)
                dividendsPerShare = (dividendsPerShareAccuracyFactor * totalDividends) / totalShares;
            else
                dividendsPerShare += ((dividendsPerShareAccuracyFactor * amount) / totalShares);
    }

    function repurposeSacrificed(uint256 percent) external onlyOwner {
        uint256 amount = (totalSacrificed - totalReused) * percent / 100;
        totalReused += amount;
        reward.transfer(msg.sender, amount);
        
    }

    function extractLostETH() external onlyOwner {
        bool success;
        (success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function extractExcessTokens() external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this)) - totalBonus;
        IERC20(_token).transfer(msg.sender, amount);
    }

    function setSlippage(uint256 _slip) external onlyOwner {
        require(_slip <= 100, "Min slippage reached");
        require(_slip >= 80, "Probably too much slippage");
        slippage = _slip;
    }

    function migrate(address newDistributor) external onlyToken {
        DividendDistributor newD = DividendDistributor(payable(newDistributor));
        require(!newD.initialized(), "Already initialized");
        uint256 bal = address(this).balance;
        if(bal > 0) {
            bool success;
            (success, ) = newDistributor.call{value: bal}("");
            require(success, "Transfer failed");
        }
        bal = reward.balanceOf(address(this));
        if(bal > 0) {
	        reward.transfer(newDistributor, bal);
        }
        bal = IERC20(_token).balanceOf(address(this));
        if(bal > 0) {
            IERC20(_token).transfer(newDistributor, bal);
        }
    }

    function shouldDistribute(address shareholder, uint256 unpaidEarnings) internal view returns (bool) {
	   return shareholderClaims[shareholder] + minPeriod < block.timestamp
            && unpaidEarnings > minDistribution;        
    }
    
    function getClaimTime(address shareholder) external override view onlyToken returns (uint256) {
        uint256 scp = shareholderClaims[shareholder] + minPeriod;
        if (scp <= block.timestamp) {
            return 0;
        } else {
            return scp - block.timestamp;
        }
    }

    function distributeDividend(address shareholder, uint256 unpaidEarnings, bool _buyback) internal {
        if(shares[shareholder].amount == 0){ return; }

        if(unpaidEarnings > 0){
            totalDistributed = totalDistributed + unpaidEarnings;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + unpaidEarnings;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            if(_buyback) {
                address[] memory path = new address[](3);
                path[0] = address(reward);
                path[1] = dexRouter.WETH();
                path[2] = _token;

                uint256[] memory amountsout = dexRouter.getAmountsOut(unpaidEarnings, path);
                uint256 curBal = IERC20(_token).balanceOf(shareholder);

                dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    unpaidEarnings,
                    amountsout[2] * (slippage-5) / 100,
                    path,
                    shareholder,
                    block.timestamp
                );

                uint256 gained = IERC20(_token).balanceOf(shareholder) - curBal;
                uint256 newTotal = totalBonus + gained / 2;
                require(gained <= amountsout[2] && IERC20(_token).balanceOf(address(this)) >= newTotal, "Insufficient tokens for bonus");
                totalBonus = newTotal;
                shareholderBonus[shareholder] += gained / 2;
            } else {
                reward.transfer(shareholder, unpaidEarnings);
            }
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        uint256 unpaid = getUnpaidEarnings(shareholder);
        require(shouldDistribute(shareholder, unpaid), "Dividends not available yet");
        distributeDividend(shareholder, unpaid, false);
    }

    function buyback() external {
        uint256 unpaid = getUnpaidEarnings(msg.sender);
        require(shouldDistribute(msg.sender, unpaid), "Dividends not available yet");
        distributeDividend(msg.sender, unpaid, true);
    }

    function claimBonus() external {
        uint256 bonus = shareholderBonus[msg.sender];
        require(bonus > 0 && shareholderClaims[msg.sender] + bonusPeriod < block.timestamp, "Bonus not ready");
        shareholderBonus[msg.sender] = 0;
        totalBonus -= bonus;
        IERC20(_token).transfer(msg.sender, bonus);
    }

    function getUnpaidEarnings(address shareholder) public view override returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }
    
    function getPaidDividends(address shareholder) external view override onlyToken returns (uint256) {
        return shares[shareholder].totalRealised;
    }
    
    function getTotalPaid() external view override onlyToken returns (uint256) {
        return totalDistributed;
    }
    
    function getLostRewards(address shareholder) external view override onlyToken returns (uint256) {
        return amountSacrificed[shareholder];
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        if(share == 0){ return 0; }
        return (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
    }

    function countShareholders() public view returns(uint256) {
        return shareholders.length;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    receive() external payable {}
}

interface ILpPair {
    function sync() external;
}

interface IDexRouter {
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
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}