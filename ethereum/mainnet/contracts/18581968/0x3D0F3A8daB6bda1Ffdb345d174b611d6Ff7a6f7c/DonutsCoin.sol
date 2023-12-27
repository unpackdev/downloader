// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

//  /$$$$$$$                                  /$$               /$$$$$$            /$$
// | $$__  $$                                | $$              /$$__  $$          |__/
// | $$  \ $$  /$$$$$$  /$$$$$$$  /$$   /$$ /$$$$$$   /$$$$$$$| $$  \__/  /$$$$$$  /$$ /$$$$$$$
// | $$  | $$ /$$__  $$| $$__  $$| $$  | $$|_  $$_/  /$$_____/| $$       /$$__  $$| $$| $$__  $$
// | $$  | $$| $$  \ $$| $$  \ $$| $$  | $$  | $$   |  $$$$$$ | $$      | $$  \ $$| $$| $$  \ $$
// | $$  | $$| $$  | $$| $$  | $$| $$  | $$  | $$ /$$\____  $$| $$    $$| $$  | $$| $$| $$  | $$
// | $$$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$/  |  $$$$//$$$$$$$/|  $$$$$$/|  $$$$$$/| $$| $$  | $$
// |_______/  \______/ |__/  |__/ \______/    \___/ |_______/  \______/  \______/ |__/|__/  |__/


/// @title DonutsCoin

/********************************************************************************************
  INTERFACE
********************************************************************************************/

interface IERC20 {
    // EVENT

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // FUNCTION

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IPair {
    // FUNCTION

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IFactory {
    // FUNCTION

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IRouter {

    // FUNCTION

    function WETH() external pure returns (address);
        
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface ICommonError {
    // ERROR

    error CannotUseCurrentAddress(address current);

    error CannotUseCurrentValue(uint256 current);

    error CannotUseCurrentState(bool current);

    error InvalidAddress(address invalid);

    error InvalidValue(uint256 invalid);
}

/********************************************************************************************
  ACCESS
********************************************************************************************/

abstract contract Ownable {
    // DATA

    address private _owner;

    // MODIFIER

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    // ERROR

    error InvalidOwner(address account);

    error UnauthorizedAccount(address account);

    // CONSTRUCTOR

    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    // EVENT

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // FUNCTION

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert UnauthorizedAccount(msg.sender);
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/********************************************************************************************
  TOKEN
********************************************************************************************/

contract DonutsCoin is Ownable, ICommonError, IERC20 {
    // DATA

    IRouter public router;

    string private constant NAME = "DonutsCoin";
    string private constant SYMBOL = "DONUTS";

    uint8 private constant DECIMALS = 18;

    uint256 private _totalSupply;

    uint256 public constant FEEDENOMINATOR = 10_000;
    uint256 public constant TRANSFERFEE = 0;

    uint256 public buyFee = 100;
    uint256 public sellFee = 200;
    uint256 public burnFeePercentage = 0; 
    uint256 public liquidityFeePercentage = 0; 
    uint256 public marketingFeePercentage = 0;

    address public marketingWallet = 0x7c983436362602Ca3A38a7d518409E1f08B10c66;
    address public projectWallet = 0x7c983436362602Ca3A38a7d518409E1f08B10c66;
    address public feeWallet = 0x7c983436362602Ca3A38a7d518409E1f08B10c66;

    uint256 public totalFeeCollected = 0;
    uint256 public minSwap = 1_000 ether;

    bool public tradeEnabled = false;
    bool public isFeeActive = false;
    bool public inSwap = false;
    bool public isSwapEnabled = false;

    address public pair;

    // MAPPING

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludeFromFees;
    mapping(address => bool) public isPairLP;

    // MODIFIER

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // ERROR

    error InvalidTradeEnabledState(bool current);

    error InvalidFeeActiveState(bool current);

    error InvalidSwapEnabledState(bool current);

    error PresaleAlreadyFinalized(bool current);

    error TradeDisabled();
    
    error InvalidFee();

    // CONSTRUCTOR

    constructor() Ownable(msg.sender) {
        _mint(projectWallet, 1_000_000 * 10 ** DECIMALS);

        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        isPairLP[pair] = true;

        isExcludeFromFees[msg.sender] = true;
        isExcludeFromFees[projectWallet] = true;
        isExcludeFromFees[address(router)] = true;
    }

    // EVENT

    event UpdateRouter(
        address oldRouter,
        address newRouter,
        address caller,
        uint256 timestamp
    );

    event UpdateMinSwap(
        uint256 oldMinSwap,
        uint256 newMinSwap,
        address caller,
        uint256 timestamp
    );

    event UpdateFeeActive(
        bool oldStatus,
        bool newStatus,
        address caller,
        uint256 timestamp
    );

    event UpdateSwapEnabled(
        bool oldStatus,
        bool newStatus,
        address caller,
        uint256 timestamp
    );

    event AutoRedeem(
        uint256 feeDistribution,
        uint256 amountToRedeem,
        address caller,
        uint256 timestamp
    );

    event EnableTrading(
        bool oldStatus,
        bool newStatus,
        address caller,
        uint256 timestamp
    );

    // FUNCTION

    /* General */

    receive() external payable {}

    function enableTrading() external onlyOwner {
        if (tradeEnabled) {
            revert InvalidTradeEnabledState(tradeEnabled);
        }
        if (isFeeActive) {
            revert InvalidFeeActiveState(isFeeActive);
        }
         if (isSwapEnabled) {
            revert InvalidSwapEnabledState(isSwapEnabled);
        }
        tradeEnabled = true;
        isFeeActive = true;
        isSwapEnabled = true;
    }

    /* Check */

    function isDonut() external pure returns (bool) {
        return true;
    }

    function circulatingSupply() external view returns (uint256) {
        return
            totalSupply() - balanceOf(address(0xdead)) - balanceOf(address(0));
    }

    /* Update */

    function updateRouter(address newRouter) external onlyOwner {
        if (address(router) == newRouter) {
            revert CannotUseCurrentAddress(newRouter);
        }
        address oldRouter = address(router);
        router = IRouter(newRouter);

        isExcludeFromFees[newRouter] = true;

        emit UpdateRouter(oldRouter, newRouter, msg.sender, block.timestamp);
        pair = IFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        isPairLP[pair] = true;
    }

    function updateMinSwap(uint256 newMinSwap) external onlyOwner {
        if (minSwap == newMinSwap) {
            revert CannotUseCurrentValue(newMinSwap);
        }
        uint256 oldMinSwap = minSwap;
        minSwap = newMinSwap;
        emit UpdateMinSwap(oldMinSwap, newMinSwap, msg.sender, block.timestamp);
    }

    function updateFeeActive(bool newStatus) external onlyOwner {
        if (isFeeActive == newStatus) {
            revert CannotUseCurrentState(newStatus);
        }
        bool oldStatus = isFeeActive;
        isFeeActive = newStatus;
        emit UpdateFeeActive(oldStatus, newStatus, msg.sender, block.timestamp);
    }

    function updateWallets(address _project, address _marketing, address _fee) external onlyOwner {
        projectWallet = _project;
        marketingWallet = _marketing;
        feeWallet = _fee;
    }

    function updateSwapEnabled(bool newStatus) external onlyOwner {
        if (isSwapEnabled == newStatus) { revert CannotUseCurrentState(newStatus); }
        bool oldStatus = isSwapEnabled;
        isSwapEnabled = newStatus;
        emit UpdateSwapEnabled(oldStatus, newStatus, msg.sender, block.timestamp);
    }

    function updateFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        if(_buyFee > 3000 || _sellFee > 3000 ) { revert InvalidFee(); }
        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function setFeePercentages(uint256 _burnFee, uint256 _liquidityFee, uint256 _marketingFee) public onlyOwner {
        require(_burnFee + _liquidityFee + _marketingFee <= 100, "Total fee percentage exceeds 100");
        burnFeePercentage = _burnFee;
        liquidityFeePercentage = _liquidityFee;
        marketingFeePercentage = _marketingFee;
    }

    function setExcludeFromFees(address user, bool status) external onlyOwner {
        if (isExcludeFromFees[user] == status) {
            revert CannotUseCurrentState(status);
        }
        isExcludeFromFees[user] = status;
    }

    function setPairLP(address lpPair, bool status) external onlyOwner {
        if (isPairLP[lpPair] == status) {
            revert CannotUseCurrentState(status);
        }
        if (
            IPair(lpPair).token0() != address(this) &&
            IPair(lpPair).token1() != address(this)
        ) {
            revert InvalidAddress(lpPair);
        }
        isPairLP[lpPair] = status;
    }

    /* Fee */

    function takeBuyFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeAmount = (amount * buyFee) / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;

        if (feeAmount > 0) {
            distributeFee(from, feeAmount);
        }

        return newAmount;
    }

    function takeSellFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeAmount = (amount * sellFee) / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;

        if (feeAmount > 0) {
            distributeFee(from, feeAmount);
        }

        return newAmount;
    }

    function swapBack() internal swapping {
        uint256 initialBalance = address(this).balance;
        uint256 firstLiquidityHalf = minSwap / 2;
        uint256 secondLiquidityHalf = minSwap - firstLiquidityHalf;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), minSwap);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            firstLiquidityHalf,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        router.addLiquidityETH{
            value: address(this).balance - initialBalance
        }(
            address(this),
            secondLiquidityHalf,
            0,
            0,
            address(0xdead),
            block.timestamp + 1_200
        );
    }

    function distributeFee(address from, uint256 feeAmount) internal swapping {
        totalFeeCollected += feeAmount;
        uint256 burnAmount = (feeAmount * burnFeePercentage) / 100;
        uint256 liquidityAmount = (feeAmount * liquidityFeePercentage) / 100;
        uint256 marketingAmount = (feeAmount * marketingFeePercentage) / 100;

        if (burnAmount > 0) {
            _balances[address(0)] += burnAmount;
        }

        if(liquidityAmount > 0){
            _balances[address(this)] += liquidityAmount;
        }

        if (marketingAmount > 0) {
            _balances[marketingWallet] += marketingAmount;
        }

        _balances[from] -= feeAmount;
        _balances[feeWallet] += (feeAmount - burnAmount - liquidityAmount - marketingAmount);
    }

    function takeTransferFee(
        address from,
        uint256 amount
    ) internal swapping returns (uint256) {
        uint256 feeAmount = (amount * TRANSFERFEE) / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        if (feeAmount > 0) {
            distributeFee(from, feeAmount);
        }
        return newAmount;
    }

    /* ERC20 Standard */

    function name() external view virtual override returns (string memory) {
        return NAME;
    }

    function symbol() external view virtual override returns (string memory) {
        return SYMBOL;
    }

    function decimals() external view virtual override returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address provider = msg.sender;
        return _transfer(provider, to, amount);
    }

    function allowance(
        address provider,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[provider][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address provider = msg.sender;
        _approve(provider, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        return _transfer(from, to, amount);
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external virtual returns (bool) {
        address provider = msg.sender;
        _approve(provider, spender, allowance(provider, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external virtual returns (bool) {
        address provider = msg.sender;
        uint256 currentAllowance = allowance(provider, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(provider, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) {
            revert InvalidAddress(account);
        }

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address provider,
        address spender,
        uint256 amount
    ) internal virtual {
        if (provider == address(0)) {
            revert InvalidAddress(provider);
        }
        if (spender == address(0)) {
            revert InvalidAddress(spender);
        }

        _allowances[provider][spender] = amount;
        emit Approval(provider, spender, amount);
    }

    function _spendAllowance(
        address provider,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(provider, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(provider, spender, currentAllowance - amount);
            }
        }
    }

    /* Additional */

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }

    /* Overrides */

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (bool) {
        if (from == address(0)) {
            revert InvalidAddress(from);
        }
        if (to == address(0)) {
            revert InvalidAddress(to);
        }

        if (
            !tradeEnabled && !isExcludeFromFees[from] && !isExcludeFromFees[to]
        ) {
            revert TradeDisabled();
        }

        if (inSwap || isExcludeFromFees[from]) {
            return _basicTransfer(from, to, amount);
        }

        uint256 newAmount = amount;

        if (isFeeActive && !isExcludeFromFees[from] && !isExcludeFromFees[to]) {
            newAmount = _beforeTokenTransfer(from, to, amount);
        }

        if (from != pair && balanceOf(address(this)) >= minSwap && isSwapEnabled) {
            swapBack();
        }

        require(
            _balances[from] >= newAmount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = _balances[from] - newAmount;
            _balances[to] += newAmount;
        }

        emit Transfer(from, to, newAmount);

        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual swapping returns (uint256) {
        if (isPairLP[from] && (buyFee > 0)) {
            return takeBuyFee(from, amount);
        }
        if (isPairLP[to] && (sellFee > 0)) {
            return takeSellFee(from, amount);
        }
        if (!isPairLP[from] && !isPairLP[to] && (TRANSFERFEE > 0)) {
            return takeTransferFee(from, amount);
        }
        return amount;
    }
}
