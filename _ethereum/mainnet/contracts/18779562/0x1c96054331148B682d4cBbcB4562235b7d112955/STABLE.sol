// SPDX-License-Identifier: MIT

/*
         ███████╗ ██████╗████████╗ █████╗ ██████╗ ██╗     ███████╗
        ██╔██╔══╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝
        ╚██████╗ ╚█████╗    ██║   ███████║██████╦╝██║     █████╗  
         ╚═██╔██╗ ╚═══██╗   ██║   ██╔══██║██╔══██╗██║     ██╔══╝  
        ███████╔╝██████╔╝   ██║   ██║  ██║██████╦╝███████╗███████╗
        ╚══════╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝

                $STABLE - JeromePowellJanetYellen69Inu
     
    Welcome to the world of $STABLE, the token where monetary policy is in YOUR hands!
    $STABLE aims to maintain a $1 peg via a community-powered rebase mechanism,
    letting holders peg $STABLE back to $1 - Jerome and Janet style. 💵🔨

    Be part of the self-adjusting currency experiment where your balance grows as we aim for equilibrium!
    Why wait for the Fed? Take control and rebase your way to fiscal stability!

    The tokenomics are as straightforward as a Fed press conference:

     🏦 Rebase at will – You're the Fed now!
     💹 Pegged to $1 – The most iconic stable value - One crisp dollar bill.
     💯 All In Liquidity – 100% supply committed, no team tokens, no taxes!
     
     🔒 Liquidity Locked - Trust is our policy.
     🥪 Sandwich Bot Protection - Trade without fear, your slippage is safe here!
     🥷 Stealth Launch - So discreet, even Nancy Pelosi didn't see us coming.

    Join the $STABLE economy today, where YOU take the Fed's seat.
    With $STABLE, when the market goes wild, you just hit rebase() and chill.

    Ready to rebase? Let's keep it $STABLE

*/

/*
    DEV NOTES:

    The supply grows and shrinks according to the amount of ETH in liquidity,
    that is how the price of $STABLE resets to 1$ every rebase, this expansion
    and contraction is what we call a rebase mechanism.

    To rebase $STABLE, you must be a holder and call the rebase() function.
    To do this go to the token contract on etherscan, click the 'Contract'
    tab, 'Write Contract', connect your wallet, rebase() and chill.

    Note there is NO official website or telegram. Any communication will be done
    through etherscan from the tokenprinter.eth wallet. The only trusted website
    to rebase $STABLE is etherscan, for now...

*/

pragma solidity 0.8.23;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}
interface IUniswapV2Router {
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

abstract contract Ownable {
    address private _owner;
    constructor() {
        _owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }
}

contract STABLE is Ownable {

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event LogRebase(uint256 totalSupply);

    string public constant name = "JeromePowellJanetYellen69Inu";
    string public constant symbol = "STABLE";
    uint8 public constant decimals = 6;

    uint256 private constant MAX_SUPPLY = type(uint128).max;
    uint256 private constant MAX_UINT256 = type(uint256).max;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant UNI_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private immutable uniswapV2Pair;
    address private immutable USDC_WETH_PAIR;
    uint256 private immutable TOTAL_BASE_UNITS;

    uint256 public totalSupply;
    uint256 private _baseUnitsPerToken;

    bool private _tradingActive = false;
    bool public limitsInEffect = true;
    uint256 private _maxWalletPercentage = 5; // 5% max wallet at launch

    mapping(address => uint256) private _baseUnitBalances;
    mapping(address => uint256) private _holderLastTransferBlock;
    mapping (address => mapping (address => uint256)) public allowance;

    constructor() {
        IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(IUniswapV2Router(UNI_ROUTER).factory());

        USDC_WETH_PAIR = uniswapV2Factory.getPair(USDC, WETH);
        uniswapV2Pair = uniswapV2Factory.createPair(address(this), WETH);

        uint256 usdcPerEth = getUSDCPerETH();

        uint256 startingETHLiquidity = 1;
        // starting price = startingETHLiquidity * usdcPerEth / supply
        uint256 INITIAL_TOKEN_SUPPLY = usdcPerEth * startingETHLiquidity * 100; // launch price = 0.01$

        totalSupply = INITIAL_TOKEN_SUPPLY;

        TOTAL_BASE_UNITS = MAX_UINT256 - (MAX_UINT256 % INITIAL_TOKEN_SUPPLY);
        _baseUnitsPerToken = TOTAL_BASE_UNITS / totalSupply;
        _baseUnitBalances[address(this)] = TOTAL_BASE_UNITS;

        emit Transfer(address(0x0), address(this), totalSupply);
    }

    // rebase() can be called by any holder
    function rebase() external {
        require(msg.sender == tx.origin); // prevent calls from contracts
        require(balanceOf(msg.sender) > 0, "Only $STABLE holders can rebase.");

        uint256 usdcPerEth = getUSDCPerETH();

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        uint256 ethReserves = WETH < address(this) ? reserve0 : reserve1;

        uint256 usdInLP = (usdcPerEth * ethReserves) / 1 ether;
        _baseUnitsPerToken = _baseUnitBalances[uniswapV2Pair] / usdInLP;
        
        totalSupply = TOTAL_BASE_UNITS / _baseUnitsPerToken;
        require(totalSupply < MAX_SUPPLY);

        IUniswapV2Pair(uniswapV2Pair).sync(); // sync pair because balances changed

        emit LogRebase(totalSupply);
    }

    function getUSDCPerETH() internal view returns (uint256) {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(USDC_WETH_PAIR).getReserves();

        uint256 usdcReserve = reserve0; // token0 is USDC (address(USDC) < address(WETH))
        uint256 ethReserve = reserve1;

        return (usdcReserve * 1 ether) / ethReserve;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _baseUnitBalances[account] / _baseUnitsPerToken;
    }

    function transfer(address to, uint256 value) external returns (bool) {
       return transferFrom(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _checkTransferCooldown(from, to);

        if (from != msg.sender && allowance[from][msg.sender] != MAX_UINT256) {
            require(allowance[from][msg.sender] >= value, "Transfer amount exceeds allowance.");
            allowance[from][msg.sender] -= value;
        }

        require(value > 0, "Transfer amount most be non-zero.");
        uint256 baseUnitValue = _baseUnitsPerToken * value;

        require(_baseUnitBalances[from] >= baseUnitValue, "Transfer amount exceeds balance.");

        if (limitsInEffect && to != uniswapV2Pair) {
            require(_baseUnitBalances[to] + baseUnitValue <= (TOTAL_BASE_UNITS / 100) * _maxWalletPercentage);
        }
        _baseUnitBalances[from] -= baseUnitValue;
        _baseUnitBalances[to] += baseUnitValue;

        emit Transfer(from, to, value);
        return true;
    }

    function _checkTransferCooldown(address from, address to) internal {

        if (from != uniswapV2Pair) { // sell or transfer
            require(_holderLastTransferBlock[from] < block.number, "Only one transfer per block allowed.");
        }

        if (to != uniswapV2Pair && to != UNI_ROUTER) {
            _holderLastTransferBlock[to] = block.number;
        }
    }

    function enableTrading() external payable onlyOwner {
        require(!_tradingActive, "Cannot reenable trading.");
        _tradingActive = true;
        
        uint256 contractBalance = balanceOf(address(this));
        allowance[address(this)][UNI_ROUTER] = contractBalance;

        IUniswapV2Router(UNI_ROUTER).addLiquidityETH{value: msg.value} (
            address(this),
            contractBalance,
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect, "Wallet limits already removed.");
        limitsInEffect = false;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}