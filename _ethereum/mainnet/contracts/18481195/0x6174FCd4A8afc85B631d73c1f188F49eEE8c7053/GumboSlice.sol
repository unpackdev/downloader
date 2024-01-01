// SPDX-License-Identifier: MIT

// Gumbo Slice
// ze moar pizza ze moar pizza
//
// https://twitter.com/PizzaGumbo
// https://gumboslice.pizza
// https://t.me/GumboSlicePortal

pragma solidity ^0.8.19;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract GumboSlice is IERC20, Ownable {
    using SafeMath for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event RequestRebase(bool increaseSupply, uint256 amount);
    event Rebase(uint256 indexed time, uint256 totalSupply);
    event RemovedLimits();
    event Log(string message, uint256 value);
    event ErrorCaught(string reason);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    uint256 constant NOMINAL_TAX = 5;

    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 public constant INITIAL_PIZZA_SUPPLY = 1 ether;
    uint256 public DELTA_SUPPLY = INITIAL_PIZZA_SUPPLY;

    // TOTAL_SLICES is a multiple of INITIAL_PIZZA_SUPPLY so that _slicesPerPizza is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 public constant TOTAL_SLICES = type(uint256).max - (type(uint256).max % INITIAL_PIZZA_SUPPLY);
    uint256 constant public zero = uint256(0);

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */

    address public SWAP_ROUTER_ADR = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public SWAP_ROUTER;
    address public immutable SWAP_PAIR;

    uint256 public _totalSupply;
    uint256 public _slicesPerPizza;
    uint256 private slicesSwapThreshold = (TOTAL_SLICES / 100000 * 25);
    uint256 public maxTxnRate;
    uint256 public maxWalletRate;

    address private oracleWallet;
    address private mktWallet;
    uint256 public vatBuy;
    uint256 public vatSell;

    bool public activateLimitRebaseRate = true;
    bool public activateLimitRebasePct = true;
    bool public givePizza = false;
    bool public swapEnabled = false;
    bool public enableUpdateTax = true;
    bool public limitsInEffect = true;
    bool public syncLP = true;
    bool inSwap;
    uint256 private lastRebaseTime = 0;
    uint256 private limitRebaseRate = 10;
    uint256 private limitDebaseRate = 5;
    uint256 private limitRebasePct = 1000;
    uint256 private limitDebasePct = 600;
    uint256 private transactionCount = 0;
    uint256 public txToSwitchTax;

    uint256 public buyToRebase = 0;
    uint256 public sellToRebase = 0;

    string _name = "Gumbo Slice";
    string _symbol = "PIZZA";

    mapping(address => uint256) public _sliceBalances;
    mapping (address => mapping (address => uint256)) public _allowedPizza;
    mapping (address => bool) public isWhitelisted;

    /* -------------------------------------------------------------------------- */
    /*                                  modifiers                                 */
    /* -------------------------------------------------------------------------- */
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleWallet, "Not oracle");
        _;
    }

	constructor(address mkt, address dev) Ownable(msg.sender) {
        // create uniswap pair
        SWAP_ROUTER = IUniswapV2Router02(SWAP_ROUTER_ADR);
        address _uniswapPair =
            IUniswapV2Factory(SWAP_ROUTER.factory()).createPair(address(this), SWAP_ROUTER.WETH());
        SWAP_PAIR = _uniswapPair;

        _allowedPizza[address(this)][address(SWAP_ROUTER)] = type(uint256).max;
        _allowedPizza[address(this)][msg.sender] = type(uint256).max;
        _allowedPizza[address(msg.sender)][address(SWAP_ROUTER)] = type(uint256).max;

        mktWallet = mkt;
        oracleWallet = dev;
        vatBuy = 30;
        vatSell = 50;
        txToSwitchTax = 50;
        maxTxnRate = 3;
        maxWalletRate = 3;

        isWhitelisted[msg.sender] = true;
        isWhitelisted[address(this)] = true;
        isWhitelisted[SWAP_ROUTER_ADR] = true;
        isWhitelisted[mktWallet] = true;
        isWhitelisted[oracleWallet] = true;
        isWhitelisted[ZERO] = true;
        isWhitelisted[DEAD] = true;

        _totalSupply = INITIAL_PIZZA_SUPPLY;
        _slicesPerPizza = TOTAL_SLICES.div(_totalSupply);

        _sliceBalances[mkt] = TOTAL_SLICES.div(100).mul(10);
        _sliceBalances[msg.sender] = TOTAL_SLICES.div(100).mul(90);

        emit Transfer(address(0), mkt, balanceOf(mkt));
        emit Transfer(address(0), msg.sender, balanceOf(msg.sender));
	}

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address holder) public view returns (uint256) {
        return _sliceBalances[holder].div(_slicesPerPizza);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function clearStuckBalance() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
    function clearStuckToken() external onlyOwner {
        _transferFrom(address(this), msg.sender, balanceOf(address(this)));
    }

    function setSwapBackSettings(bool _enabled, uint256 _pt) external onlyOwner {
        swapEnabled = _enabled;
        slicesSwapThreshold = (TOTAL_SLICES * _pt) / 100000;
    }

    function enablePizzaExchange() external onlyOwner {
        require(!givePizza, "Token launched");
        givePizza = true;
        swapEnabled = true;
    }

    function setMaxTxWalletRate(uint256 _rtx, uint256 _rw) external onlyOwner {
        maxTxnRate = _rtx;
        maxWalletRate = _rw;
    }

    function whitelistWallet(address _address, bool _isWhitelisted) external onlyOwner {
        isWhitelisted[_address] = _isWhitelisted;
    }

    function setTxToSwitchTax(uint256 _c) external  onlyOwner {
        txToSwitchTax = _c;
    }

    function setToFinalTax() external onlyOwner {
        enableUpdateTax = false;
        vatBuy = NOMINAL_TAX;
        vatSell = NOMINAL_TAX;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   oracle                                   */
    /* -------------------------------------------------------------------------- */
    function setActivateRebaseLimit(bool _l, bool _p) external  onlyOracle {
        activateLimitRebaseRate = _l;
        activateLimitRebasePct = _p;
    }

    function removeLimit() external onlyOracle {
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function setSyncLP(bool _s) external  onlyOracle {
        syncLP = _s;
    }

    function setRebaseLimit(uint256 _r, uint256 _pct) external  onlyOracle {
        limitRebaseRate = _r;
        limitRebasePct = _pct;
    }

    function setDebaseLimit(uint256 _r, uint256 _pct) external  onlyOracle {
        limitDebaseRate = _r;
        limitDebasePct = _pct;
    }

    function canRebase() public view returns (bool) {
        return sellToRebase != buyToRebase;
    }

    function buyback() external payable onlyOracle {
        require(msg.value > 0, "No ETH sent");
        address[] memory path = new address[](2);
        path[0] = address(SWAP_ROUTER.WETH());
        path[1] = address(this);
        SWAP_ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            DEAD,
            block.timestamp
        );
    }

    function rebase() external onlyOracle {
        uint256 currentTime = block.timestamp;
        uint256 newSupply = _totalSupply;
        uint256 rebaseDelta = 0;
        bool increaseSupply = false;
        if (sellToRebase > buyToRebase){
            rebaseDelta = sellToRebase;
        } else if (buyToRebase > sellToRebase) {
            rebaseDelta = buyToRebase;
            increaseSupply = true;
        } else {
            emit Log("same amount, no need to rebase", 0);
            return;
        }

        if (currentTime >= lastRebaseTime + 1 days) {
            lastRebaseTime = currentTime;
            DELTA_SUPPLY = newSupply;
        }

        if (increaseSupply) {
            if (activateLimitRebasePct) {
                if (rebaseDelta > DELTA_SUPPLY.mul(limitRebasePct).div(1000)) {
                    rebaseDelta = DELTA_SUPPLY.mul(limitRebasePct).div(1000);
                }
            }
            if (activateLimitRebaseRate && _totalSupply.add(rebaseDelta) > DELTA_SUPPLY.mul(limitRebaseRate)){
                newSupply = DELTA_SUPPLY.mul(limitRebaseRate);
            } else {
                newSupply = _totalSupply.add(rebaseDelta);
            }
        } else { 
            if (activateLimitRebasePct) {
                if (rebaseDelta > DELTA_SUPPLY.mul(limitDebasePct).div(1000)) {
                    rebaseDelta = DELTA_SUPPLY.mul(limitDebasePct).div(1000);
                }
            }
            if (activateLimitRebaseRate && _totalSupply.sub(rebaseDelta) < DELTA_SUPPLY.div(limitDebaseRate)){
                newSupply = DELTA_SUPPLY.div(limitDebaseRate);
            } else {
                newSupply = _totalSupply.sub(rebaseDelta);
            }
        }

        if (newSupply > MAX_SUPPLY) {
            newSupply = MAX_SUPPLY;
        }

        _totalSupply = newSupply;
        _slicesPerPizza = TOTAL_SLICES.div(_totalSupply);
        sellToRebase = 0;
        buyToRebase = 0;

        if (syncLP){
            lpSync();
        }

        emit Rebase(currentTime, _totalSupply);
    }
    

    /* -------------------------------------------------------------------------- */
    /*                                   private                                  */
    /* -------------------------------------------------------------------------- */
    function updateTaxes() internal {
        if (vatSell > NOMINAL_TAX) {
            transactionCount += 1;
        }
        if (transactionCount == txToSwitchTax) {
            vatBuy = 15;
            vatSell = 30;
        } else if (transactionCount == txToSwitchTax.mul(2)) {
            vatBuy = 10;
            vatSell = 20;
        } else if (transactionCount >= txToSwitchTax.mul(3) && vatSell > NOMINAL_TAX) {
            vatBuy = NOMINAL_TAX;
            vatSell = NOMINAL_TAX;
            enableUpdateTax = false;
        }
    }

    function lpSync() internal {
        IUniswapV2Pair _pair = IUniswapV2Pair(SWAP_PAIR);
        try _pair.sync() {} catch {}
    }

    /* -------------------------------------------------------------------------- */
    /*                                    ERC20                                   */
    /* -------------------------------------------------------------------------- */
    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowedPizza[owner_][spender];
    }
    function approve(address spender, uint256 value) public returns (bool) {
        _allowedPizza[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowedPizza[msg.sender][spender] = _allowedPizza[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedPizza[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = _allowedPizza[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedPizza[msg.sender][spender] = 0;
        } else {
            _allowedPizza[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedPizza[msg.sender][spender]);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowedPizza[sender][msg.sender] != type(uint256).max) {
            require(_allowedPizza[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
            _allowedPizza[sender][msg.sender] = _allowedPizza[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(sender != DEAD, "Please use a good address");
        require(sender != ZERO, "Please use a good address");

        uint256 sliceAmount = amount.mul(_slicesPerPizza);
        require(_sliceBalances[sender] >= sliceAmount, "Insufficient Balance");

        if(!inSwap && !isWhitelisted[sender] && !isWhitelisted[recipient]){
            require(givePizza, "Trading not live");
            if(limitsInEffect){
                if (sender == SWAP_PAIR){
                    require(amount <= _totalSupply.mul(maxTxnRate).div(1000), "Max Tx Exceeded");
                }
                if (recipient != SWAP_PAIR){
                    require(balanceOf(recipient) + amount <= _totalSupply.mul(maxWalletRate).div(1000), "Max Wallet Exceeded");
                }
            }
            if (_shouldSwapBack(recipient)){
                try this.swapBack(){} catch {}
            }

            uint256 vatAmount = 0;
            if(sender == SWAP_PAIR){
                emit RequestRebase(true, amount);
                buyToRebase += amount;
                vatAmount = sliceAmount.mul(vatBuy).div(100);
            }
            else if (recipient == SWAP_PAIR) {
                emit RequestRebase(false, amount);
                sellToRebase += amount;
                vatAmount = sliceAmount.mul(vatSell).div(100);
            }

            if(vatAmount > 0){
                _sliceBalances[sender] -= vatAmount;
                _sliceBalances[address(this)] += vatAmount;
                emit Transfer(sender, address(this), vatAmount.div(_slicesPerPizza));
                sliceAmount -= vatAmount;

                if (enableUpdateTax) {
                    updateTaxes();
                }
            }
        }

        _sliceBalances[sender] = _sliceBalances[sender].sub(sliceAmount);
        _sliceBalances[recipient] = _sliceBalances[recipient].add(sliceAmount);

        emit Log("Amount transfered", sliceAmount.div(_slicesPerPizza));

        emit Transfer(sender, recipient, sliceAmount.div(_slicesPerPizza));

        return true;
    }

    function _shouldSwapBack(address recipient) internal view returns (bool) {
        return recipient == SWAP_PAIR && !inSwap && swapEnabled && balanceOf(address(this)) >= slicesSwapThreshold.div(_slicesPerPizza);
    }

    function swapBack() public swapping {
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance == 0){
            return;
        }

        if(contractBalance > slicesSwapThreshold.div(_slicesPerPizza).mul(20)){
            contractBalance = slicesSwapThreshold.div(_slicesPerPizza).mul(20);
        }

        swapTokensForETH(contractBalance);
    }

    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(SWAP_ROUTER.WETH());

        SWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(oracleWallet),
            block.timestamp
        );
    }

    receive() external payable {}
}