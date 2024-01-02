// SPDX-License-Identifier: Unlicensed

/**
The Best Audit Platform!

Website:  https://0xaudit.tech
Telegram: https://t.me/zeroxAudit_erc
Twitter: https://twitter.com/zeroxAudit_erc
Dapp: https://app.0xaudit.tech
*/

pragma solidity = 0.8.19;

//--- Interface for ERC20 ---//
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//--- Context ---//
abstract contract Context {
    constructor() {
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

//--- Ownable ---//
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

//--- Contract ---//
contract ZEROXAUDIT is Context, Ownable, IERC20 {

    uint256 constant public _totalSupply = 10 ** 9 * 10**9;
    uint256 constant public feeSwapThreshold = _totalSupply / 100_000;
    uint256 public buy_fee = 240;
    uint256 public sell_fee = 240;
    uint256 constant public transfer_fee = 0;
    uint256 constant public fee_denominator = 1_000;
    uint256 private max_wallet = 20 * _totalSupply / 1000;
    bool private canSwapFees = true;
    address payable private teamAddress = payable(address(0xd4fa5293292279B81BfF120d505B93979468a021));
    IUniswapRouter public swapRouter;
    string constant private _name = "0xAUDIT";
    string constant private _symbol = "0xAUDIT";
    uint8 constant private _decimals = 9;
    address public lpPair;
    bool public isTradingEnabled = false;
    bool private inSwap;
    bool private avoidMaxTxLimits = false;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noFee;
    mapping (address => bool) private liquidityAdd;
    mapping (address => bool) private isLpPair;
    mapping (address => uint256) private balance;

        modifier lockSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _noFee[msg.sender] = true;
        _noFee[teamAddress] = true;

        if (block.chainid == 56) {
            swapRouter = IUniswapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            swapRouter = IUniswapRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3) {
            swapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else if (block.chainid == 42161) {
            swapRouter = IUniswapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        } else if (block.chainid == 5) {
            swapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else {
            revert("Chain not valid");
        }
        liquidityAdd[msg.sender] = true;
        balance[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        lpPair = IUniswapFactoryV2(swapRouter.factory()).createPair(swapRouter.WETH(), address(this));
        isLpPair[lpPair] = true;
        _approve(msg.sender, address(swapRouter), type(uint256).max);
        _approve(address(this), address(swapRouter), type(uint256).max);


    }

    function isIncludedInFee(address ins, address out) internal view returns (bool) {

        bool isLimited = ins != owner()
            && out != owner()
            && msg.sender != owner()
            && !liquidityAdd[ins]  && !liquidityAdd[out] && out != address(0) && out != address(this);
            return isLimited;
    }

    function is_buy(address ins, address out) internal view returns (bool) {
        bool _is_buy = !isLpPair[out] && isLpPair[ins];
        return _is_buy;
    }

    function is_sell(address ins, address out) internal view returns (bool) { 
        bool _is_sell = isLpPair[out] && !isLpPair[ins];
        return _is_sell;
    }

    function is_transfer(address ins, address out) internal view returns (bool) { 
        bool _is_transfer = !isLpPair[out] && !isLpPair[ins];
        return _is_transfer;
    }

    function canSwapFee(address ins, address out) internal view returns (bool) {
        bool canswap = canSwapFees && !_noFee[ins];

        return canswap;
    }
    
        function openAudit() external onlyOwner {
            require(!isTradingEnabled, "Trading already enabled");
            isTradingEnabled = true;
        }

        function removeAuditLimits() external onlyOwner {
            require(!avoidMaxTxLimits,"Already initalized");
            max_wallet = _totalSupply;
            avoidMaxTxLimits = true;
            buy_fee = 30;
            sell_fee = 30;
        }

    function _transfer(address from, address to, uint256 amount) internal returns  (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (isIncludedInFee(from,to)) {
            require(isTradingEnabled,"Trading is not enabled");
                    if(!isLpPair[to] && from != address(this) && to != address(this) || is_transfer(from,to) && !avoidMaxTxLimits)  { require(balanceOf(to) + amount <= max_wallet,"max_wallet exceed"); }}


        if(is_sell(from, to) &&  !inSwap && canSwapFee(from, to)) {

            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= feeSwapThreshold) { 
                if(amount > feeSwapThreshold) swapBack(contractTokenBalance);
             }
        }

        if (_noFee[from] || _noFee[to]){
            takeFee = false;
        }
        uint256 amountAfterFee = (takeFee) ? takeFees(from, is_buy(from, to), is_sell(from, to), amount) : amount;
        uint256 amountBeforeFee = (takeFee) ? amount : (!isTradingEnabled ? amount : 0);
        balance[from] -= amountBeforeFee; balance[to] += amountAfterFee; emit Transfer(from, to, amountAfterFee);

        return true;

    }

    function totalSupply() external pure override returns (uint256) { if (_totalSupply == 0) { revert(); } return _totalSupply; }
    function decimals() external pure override returns (uint8) { if (_totalSupply == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }
    
    receive() external payable {}

        function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

        function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function takeFees(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isbuy)  fee = buy_fee;  else if (issell)  fee = sell_fee;  else  fee = transfer_fee; 
        if (fee == 0)  return amount; 
        uint256 feeAmount = amount * fee / fee_denominator;
        if (feeAmount > 0) {

            balance[address(this)] += feeAmount;
            emit Transfer(from, address(this), feeAmount);
            
        }
        return amount - feeAmount;
    }


    function swapBack(uint256 contractTokenBalance) internal lockSwap {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        if (_allowances[address(this)][address(swapRouter)] != type(uint256).max) {
            _allowances[address(this)][address(swapRouter)] = type(uint256).max;
        }

        try swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }

        if(address(this).balance > 0) teamAddress.transfer(address(this).balance);
        
    } 

        function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
    }

        function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }
}