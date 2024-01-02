/*

You cook, Butler serves: Create, launch & manage your own token just by using Telegram: t.me/devbutler_bot
But here's the catch: You cannot join DevButler - until you get invited.

Web: devbutler.org
Whitepaper: devbutler.org/pdf/devbutler.pdf
Twitter: x.com/thedevbutler
Telegram: t.me/devbutler
GitBook: devbutler.gitbook.io/devbutler
Medium: medium.com/@devbutler

Security Mechanisms:
- Liquidity is locked, RemoveLiquidity() via Uniswap is disabled
- Owner can only get back his initial liquidity by calling fairExit(), the price will remain stable due to burning tokens
- After fairExit() is called, ownership will be renounced and the token will be community-driven
- MaxWallet & MaxTx is limited to minimum 1%
- Fees are immutable

Sincerly yours,
 The Butler

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
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;

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

contract DevButler is Ownable, IERC20 {

    IUniswapV2Router02 public constant UNISWAP_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public UNISWAP_PAIR;

    address private constant DEVBUTLER_FEE_RECIPIENT = 0xa55dc4860EE12BAA7dDe8043708B582a4eeBe617;
    address private constant DEVBUTLER_AIRDROP = 0x77e51f06239cecea9A3F61770EF0Cc5a26424d43;

    uint8 private constant DEVBUTLER_FEE = 50; // = 5 %
    uint8 private constant FAIR_EXIT_OWNER_REFUND_PERCENTAGE = 100; // = 100 %
    uint16 private constant HOLDER_SHARE_THRESHOLD = 10000;
    uint8 private constant FEE_TRANSFER_INTERVAL = 5;
    string constant private NAME = "DevButler";
    string constant private SYMBOL = "BUTLER";
    uint8 constant private DECIMALS = 18;
    uint256 constant private TOTAL_SUPPLY = 1000000 * (10 ** DECIMALS); // 1 Million $BUTLER in total
    uint256 constant private AIRDROP_SUPPLY = 50000 * (10 ** DECIMALS); // 5 % of Supply for Airdrops

    uint256 private MAX_TRANSACTION = 20000 * (10 ** DECIMALS);
    uint256 private MAX_WALLET = 20000 * (10 ** DECIMALS);

    bool private ownerLeft = false;
    bool private fairExiting = false;
    bool private feesPaying = false;

    uint256 private sellCount;
    uint256 private initialLiquidityInETH;
    uint256 private initialMintedLiquidityPoolTokens;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private excludedFromFees;
    mapping(address => bool) private excludedFromMaxTransaction;

    event DevButlerDeploy(address deployer);

    constructor() payable {
        _balances[address(this)] = TOTAL_SUPPLY - AIRDROP_SUPPLY;
        emit Transfer(address(0), address(this), _balances[address(this)]);
        _balances[DEVBUTLER_AIRDROP] = AIRDROP_SUPPLY;
        emit Transfer(address(0), DEVBUTLER_AIRDROP, _balances[DEVBUTLER_AIRDROP]);

        UNISWAP_PAIR = IUniswapV2Factory(UNISWAP_ROUTER.factory()).createPair(address(this), UNISWAP_ROUTER.WETH());
        _approve(address(this), address(UNISWAP_ROUTER), type(uint256).max);

        excludedFromFees[DEVBUTLER_FEE_RECIPIENT] = true;
        excludedFromFees[getOwner()] = true;
        excludedFromFees[address(0)] = true;
        excludedFromFees[address(this)] = true;

        excludedFromMaxTransaction[DEVBUTLER_FEE_RECIPIENT] = true;
        excludedFromMaxTransaction[getOwner()] = true;
        excludedFromMaxTransaction[address(this)] = true;
        excludedFromMaxTransaction[address(UNISWAP_ROUTER)] = true;
        excludedFromMaxTransaction[UNISWAP_PAIR] = true;
    }

    receive() external payable {}

    function name() public view virtual returns (string memory) {
        return NAME;
    }

    function symbol() public view virtual returns (string memory) {
        return SYMBOL;
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
        uint256 totalFees = 0;
        bool takeFees = !fairExiting && !feesPaying && !excludedFromFees[sender] && !excludedFromFees[recipient];
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
        if (takeFees) {
            totalFees = totalFees + ((DEVBUTLER_FEE * amount) / 1000);
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

        if (!fairExiting && !ownerLeft && IERC20(UNISWAP_PAIR).balanceOf(address(this)) < initialMintedLiquidityPoolTokens) {
            revert("You cannot decrease liquidity. Call fairExit() to get funds back");
        }
    }

    function manualTransferFees() external onlyOwner {
        transferFees();
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
                    DEVBUTLER_FEE_RECIPIENT,
                    block.timestamp) {} catch {}
            }
            feesPaying = false;
        }
    }

    function setMaxTransaction(uint256 val) external onlyOwner {
        require(val >= (TOTAL_SUPPLY / 100), "Max Tx cannot be less than 1% of total supply");
        MAX_TRANSACTION = val;
    }

    function setMaxWallet(uint256 val) external onlyOwner {
        require(val >= (TOTAL_SUPPLY / 100), "Max Wallet cannot be less than 1% of total supply");
        MAX_WALLET = val;
    }

    function calculateETHShare(uint256 holderBalance, uint256 totalBalance, uint256 remainingETH) internal pure returns (uint256) {
        return ((remainingETH * holderBalance * HOLDER_SHARE_THRESHOLD) / totalBalance) / HOLDER_SHARE_THRESHOLD;
    }

    function addLiquidity() internal onlyOwner {
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

    function openTrading() external onlyOwner payable {
        addLiquidity();
    }

    function fairExit() external onlyOwner {
        require(!fairExiting, "Already exiting");
        fairExiting = true;
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(UNISWAP_PAIR).getReserves();
        uint256 lpTokensToRemove = calculateETHShare((FAIR_EXIT_OWNER_REFUND_PERCENTAGE * initialLiquidityInETH / 100), 
            (IUniswapV2Pair(UNISWAP_PAIR).token0() == address(this) ? reserve1 : reserve0), initialMintedLiquidityPoolTokens);
        IERC20(UNISWAP_PAIR).approve(address(UNISWAP_ROUTER), type(uint256).max);
        UNISWAP_ROUTER.removeLiquidityETH(
            address(this),
            lpTokensToRemove > initialMintedLiquidityPoolTokens ? initialMintedLiquidityPoolTokens : lpTokensToRemove,
            0,
            0,
            getOwner(),
            block.timestamp
        );
        transferOwnership(address(0));
        fairExiting = false;
        ownerLeft = true;
    }

}