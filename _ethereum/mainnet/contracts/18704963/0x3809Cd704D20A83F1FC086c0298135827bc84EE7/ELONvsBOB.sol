/*

Entering the ring today... ELON vs BOB !

Telegram: t.me/oktagon_eth
X: x.com/oktagon_eth

Brought to you by Oktagon Ethereum:
✅ One launch per week - same day, same time, same dev
✅ Initial Liquidity is minimum 1 ETH 
✅ One hour after launch, the initial liquidity will be taken out, the token will be renounced and 100% of the LP will be burnt
✅ Technology by DevButler (x.com/thedevbutler)

*/

pragma solidity >= 0.8.21;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract Ownable {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller must be owner");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;
    }
}

contract ELONvsBOB is Ownable, IERC20 {

    IUniswapV2Router02 public constant UNISWAP_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public UNISWAP_PAIR;

    address private constant FEE_RECIPIENT = 0xa55dc4860EE12BAA7dDe8043708B582a4eeBe617;
    uint8 constant private DECIMALS = 18;
    uint8 private constant FAIR_EXIT_OWNER_REFUND_PERCENTAGE = 100; // = 100 %
    uint16 private constant HOLDER_SHARE_THRESHOLD = 10000;
    uint256 constant private TOTAL_SUPPLY = 1000000 * (10 ** DECIMALS);
    uint256 constant private MAX_TRANSACTION = 20000 * (10 ** DECIMALS);
    uint256 constant private MAX_WALLET = 20000 * (10 ** DECIMALS);

    uint8 private FEE = 50; // = 5 %
    uint8 private FEE_TRANSFER_INTERVAL = 5;

    bool private fairExiting = false;
    bool private feesPaying = false;

    uint256 private sellCount;
    uint256 private initialLiquidityInETH;
    uint256 private initialMintedLiquidityPoolTokens;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private excludedFromFees;
    mapping(address => bool) private excludedFromMaxTransaction;

    constructor() payable {
        _balances[address(this)] = TOTAL_SUPPLY;
        emit Transfer(address(0), address(this), _balances[address(this)]);

        UNISWAP_PAIR = IUniswapV2Factory(UNISWAP_ROUTER.factory()).createPair(address(this), UNISWAP_ROUTER.WETH());
        _approve(address(this), address(UNISWAP_ROUTER), type(uint256).max);

        excludedFromFees[FEE_RECIPIENT] = true;
        excludedFromFees[getOwner()] = true;
        excludedFromFees[address(0)] = true;
        excludedFromFees[address(this)] = true;

        excludedFromMaxTransaction[FEE_RECIPIENT] = true;
        excludedFromMaxTransaction[getOwner()] = true;
        excludedFromMaxTransaction[address(this)] = true;
        excludedFromMaxTransaction[address(UNISWAP_ROUTER)] = true;
        excludedFromMaxTransaction[UNISWAP_PAIR] = true;
    }

    receive() external payable {
    }

    function name() public view virtual returns (string memory) {
        return "ELON versus BOB";
    }

    function symbol() public view virtual returns (string memory) {
        return "ELONvsBOB";
    }

    function decimals() public view virtual returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        doTransfer(msg.sender, recipient, amount);
        return true;
    }

	function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
		address spender = msg.sender;
		uint256 currentAllowance = allowance(from, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "ERC20: Insufficient allowance");
            _approve(from, spender, currentAllowance - value);
        }
        doTransfer(from, to, value);
        return true;
    }

    function doTransfer(address sender, address recipient, uint256 amount) internal virtual {
        if (UNISWAP_PAIR == sender) {
            if (!excludedFromMaxTransaction[recipient]) {
                require(amount <= MAX_TRANSACTION, "Buy transfer amount exceeds MAX TX");
                require(amount + _balances[recipient] <= MAX_WALLET, "Buy transfer amount exceeds MAX WALLET");
            }
        } else if (UNISWAP_PAIR == recipient) {
            if (!excludedFromMaxTransaction[sender]) {
                require(amount <= MAX_TRANSACTION, "Sell transfer amount exceeds MAX TX");
                sellCount = sellCount + 1;
                if (sellCount % FEE_TRANSFER_INTERVAL == 0) {
                    transferFees();
                }
            }
        }

        uint256 totalFees = 0;
        if (FEE != 0 && !fairExiting && !feesPaying && !excludedFromFees[sender] && !excludedFromFees[recipient]) {
            totalFees = totalFees + ((FEE * amount) / 1000);
        }        

        require(_balances[sender] >= amount, "Integer Underflow Protection");

        if (totalFees != 0) {
            amount = amount - totalFees;
            _balances[sender] = _balances[sender] - totalFees;
            _balances[address(this)] = _balances[address(this)] + totalFees;
            emit Transfer(sender, address(this), totalFees);
        }

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);
    }

    function transferFees() internal {
        if (!feesPaying) {
            feesPaying = true;
            if (_balances[address(this)] != 0) {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = UNISWAP_ROUTER.WETH();
                try UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _balances[address(this)],
                    0,
                    path,
                    FEE_RECIPIENT,
                    block.timestamp) {} catch {}
            }
            feesPaying = false;
        }
    }

    function openTrading() external onlyOwner payable {
        (, uint256 amountETH, uint256 liquidity) = UNISWAP_ROUTER.addLiquidityETH{value: address(this).balance}(
            address(this),
            _balances[address(this)],
            0,
            0,
            address(this),
            block.timestamp
        );
        initialLiquidityInETH = initialLiquidityInETH + amountETH;
        initialMintedLiquidityPoolTokens = initialMintedLiquidityPoolTokens + liquidity;
    }

    function fairExit() external onlyOwner {
        require(!fairExiting, "Already exiting");
        fairExiting = true;
        transferFees();
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(UNISWAP_PAIR).getReserves();
        uint256 lpTokensToRemove = ((initialMintedLiquidityPoolTokens * (FAIR_EXIT_OWNER_REFUND_PERCENTAGE * initialLiquidityInETH / 100) 
            * HOLDER_SHARE_THRESHOLD) / (IUniswapV2Pair(UNISWAP_PAIR).token0() == address(this) ? reserve1 : reserve0)) / HOLDER_SHARE_THRESHOLD;
        IERC20(UNISWAP_PAIR).approve(address(UNISWAP_ROUTER), type(uint256).max);
        UNISWAP_ROUTER.removeLiquidityETH(
            address(this),
            lpTokensToRemove > initialMintedLiquidityPoolTokens ? initialMintedLiquidityPoolTokens : lpTokensToRemove,
            0,
            0,
            address(this),
            block.timestamp
        );
        try IERC20(address(this)).transfer(
            0x000000000000000000000000000000000000dEaD, 
            _balances[address(this)]) {} catch {}
        try IERC20(UNISWAP_PAIR).transfer(
            0x000000000000000000000000000000000000dEaD, 
            IERC20(UNISWAP_PAIR).balanceOf(address(this))) {} catch {}
        payable(getOwner()).transfer(address(this).balance);
        FEE_TRANSFER_INTERVAL = 1;
        FEE = 10;
        transferOwnership(address(0));
        fairExiting = false;
    }

}