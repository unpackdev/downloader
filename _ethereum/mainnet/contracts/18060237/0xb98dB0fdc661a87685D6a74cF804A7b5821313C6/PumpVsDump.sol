// https://t.me/pumpvsdumpportal

/*
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣠⣤⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣠⣤⡶⠟⠛⠉⠉⠉⠉⠉⠛⠛⠻⣦⣄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢠⡾⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣦⡀⠀⠀⠀
⠀⠀⠀⣼⠇⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⡀⠀⠹⣷⠀⠀⠀
⠀⠀⣴⡟⠀⠀⠀⠀⠙⠛⠛⠉⠉⠉⠉⠙⠛⠛⠛⠛⠀⠀⢻⡇⠀⠀
⠀⠀⣿⡇⠀⠀⠀⠀⠀⢠⣴⠶⠶⠿⠿⠂⠀⠀⢠⡾⠿⠿⠿⣿⡀⠀
⠀⠀⢿⡇⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⠀⠀⠀⣀⠀⠀⢀⣀⣿⠇⠀
⠀⠀⠘⣷⠀⠀⠀⠀⠀⠀⠀⠘⠦⠿⠿⠇⠀⠀⢿⡆⠐⠯⠿⣿⡀⠀
⠀⠀⠀⠹⣧⡀⠀⣶⠀⠀⠀⠀⠀⠀⣤⡄⠀⠀⠈⢻⡆⠀⠀⣿⡇⠀
⠀⠀⠀⠀⢹⣧⠀⠹⣷⠀⠀⠀⠀⠀⠘⠛⠀⠛⠛⠛⠃⠀⠀⣿⠇⠀
⠀⠀⠀⠀⢸⣿⠀⠀⠻⣦⡀⠀⠀⢠⣶⣦⣤⣤⣤⣄⠀⢀⣼⠏⠀⠀
⠀⠀⠀⠀⢸⡿⠀⠀⠀⠉⠻⣦⡀⠀⠁⠀⠉⠉⠉⠉⠀⣼⡇⠀⠀⠀
⠀⠀⠀⠀⣼⡇⠀⠀⠀⠀⠀⠈⠻⣦⣀⠀⠀⠀⣀⣤⡾⠋⠀⠀⠀⠀
⢀⣀⣠⣾⠏⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠛⠛⠛⣿⣅⣀⣀⣀⣀⣀⡀
⠈⠋⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠛⠛⠛⠛⠛⠁


*/

// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ERC20.sol";

pragma solidity ^0.8.4;

contract PumpVsDump is Ownable, ERC20 {
    IUniswapV2Router02 public uniswapV2Router;
    bool public tradingAllowed;
    address private teamWallet;
    address public uniswapV2Pair;
    address public stableCoin;

    // Variable Tax Info
    bool public customTaxMode;
    uint256 pumpBuyTax = 1;
    uint256 pumpSellTax = 1;
    uint256 dumpBuyTax = 1;
    uint256 dumpSellTax = 1;

    // Tax variables
    bool public pumping;
    bool public postLaunch;
    bool public taxesEnabled = true;
    bool public limitsEnabled = true;
    uint256 public lastPriceCheckTimeStamp;
    uint256 public lastTokenPrice;
    uint256 public intevalTime;
    uint256 public autoBuyTax;
    uint256 public autoSellTax;
    uint256 public initialBuyTaxPercent = 1;
    uint256 public initialSellTaxPercent = 1;
    uint256 public minAmountToSwapTaxes;
    uint256 public maxWalletAmount;
    bool inSwapAndLiq;

    mapping(address => bool) public _isExcludedFromFees;
    event Pumping(bool _Pumping);

    modifier lockTheSwap() {
        inSwapAndLiq = true;
        _;
        inSwapAndLiq = false;
    }

    receive() external payable {}

    constructor() ERC20("PumpVsDump", "PvD") {
        _mint(address(this), 90_000_000 * 10 ** 18);
        _mint(msg.sender, 10_000_000 * 10 ** 18);

        minAmountToSwapTaxes = (totalSupply() * 3) / 1000;
        maxWalletAmount = (totalSupply() * 2) / 100;
        teamWallet = 0xB224efebD45853ECd0AFcB32d0E9e9A000F6F19C;
        stableCoin = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        intevalTime = 300;

        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[teamWallet] = true;
        _isExcludedFromFees[address(this)] = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer must be greater than 0");

        if (!tradingAllowed) {
            require(
                from == owner() || to == owner() || from == address(this),
                "Trading not active yet"
            );
        }

        if (limitsEnabled && from == uniswapV2Pair) {
            if (!_isExcludedFromFees[to]) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "Max Wallet In Effect"
                );
            }
        }

        if (
            postLaunch &&
            block.timestamp >= lastPriceCheckTimeStamp + intevalTime
        ) {
            updatedAutoTax();
        }

        uint256 taxAmount;

        if (taxesEnabled) {
            //Buy
            if (from == uniswapV2Pair) {
                if (!_isExcludedFromFees[to]) {
                    taxAmount =
                        ((postLaunch ? autoBuyTax : initialBuyTaxPercent) *
                            amount) /
                        100;
                }
            }
            // Sell
            if (to == uniswapV2Pair) {
                if (!_isExcludedFromFees[from]) {
                    taxAmount =
                        ((postLaunch ? autoSellTax : initialSellTaxPercent) *
                            amount) /
                        100;
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            bool overMinTokenBalance = contractTokenBalance >=
                minAmountToSwapTaxes;
            if (
                overMinTokenBalance &&
                !inSwapAndLiq &&
                from != uniswapV2Pair &&
                !_isExcludedFromFees[from]
            ) {
                handleTax(contractTokenBalance);
            }
        }

        // Fees
        if (taxAmount > 0) {
            uint256 userAmount = amount - taxAmount;
            super._transfer(from, address(this), taxAmount);
            super._transfer(from, to, userAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function addLiquidity() external payable onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        // approve token transfer to cover all possible scenarios
        _approve(
            address(this),
            address(uniswapV2Router),
            balanceOf(address(this))
        );

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function handleTax(uint256 _taxesInContract) internal lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), _taxesInContract);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _taxesInContract,
            0, // accept any amount of ETH
            path,
            teamWallet,
            block.timestamp
        );
    }

    function changeTeamWallet(address _newTeamWallet) external onlyOwner {
        teamWallet = _newTeamWallet;
    }

    function changeLaunchTaxPercent(
        uint256 _newBuyTaxPercent,
        uint256 _newSellTaxPercent
    ) external onlyOwner {
        require(!postLaunch, "Cannot manually change once autotax is enabled");
        initialBuyTaxPercent = _newBuyTaxPercent;
        initialSellTaxPercent = _newSellTaxPercent;
    }

    function excludeFromFees(
        address _address,
        bool _isExcluded
    ) external onlyOwner {
        _isExcludedFromFees[_address] = _isExcluded;
    }

    function changeMinAmountToSwapTaxes(
        uint256 newMinAmount
    ) external onlyOwner {
        require(newMinAmount > 0, "Cannot set to zero");
        minAmountToSwapTaxes = newMinAmount;
    }

    function enableAutoTax() external onlyOwner {
        require(!postLaunch, "AutoTax already enabled");
        updatedAutoTax();
        postLaunch = true;
    }

    function enableTaxes(bool _enable) external onlyOwner {
        taxesEnabled = _enable;
    }

    function setAutoTax(
        uint256 _autoBuyTax,
        uint256 _autoSellTax
    ) external onlyOwner {
        require(
            _autoBuyTax <= 10 && _autoSellTax <= 10,
            "Taxes cannot be higher than 10"
        );
        autoBuyTax = _autoBuyTax;
        autoSellTax = _autoSellTax;
    }

    function setIntervalTime(uint256 _newIntervalTime) external onlyOwner {
        intevalTime = _newIntervalTime;
    }

    function activate(uint256[2] memory _taxes) external onlyOwner {
        require(!tradingAllowed, "Trading not paused");
        tradingAllowed = true;
        initialBuyTaxPercent = _taxes[0];
        initialSellTaxPercent = _taxes[1];
        lastTokenPrice = checkCurrentPrice();
        lastPriceCheckTimeStamp = block.timestamp;
    }

    function toggleLimits(bool _limitsEnabed) external onlyOwner {
        limitsEnabled = _limitsEnabed;
    }

    function updateStableCoin(address _newStable) external onlyOwner {
        stableCoin = _newStable;
    }

    function togleTaxMode() external onlyOwner {
        customTaxMode = !customTaxMode;
    }

    function changeTaxMode(
        uint256 _pumpSellTx,
        uint256 _pumpBuyTx,
        uint256 _dumpSellTx,
        uint256 _dumpBuyTx
    ) public onlyOwner {
        require(_pumpSellTx < 10, "Surpasses Tax Limit");
        require(_pumpBuyTx < 10, "Surpasses Tax Limit");
        require(_dumpSellTx < 10, "Surpasses Tax Limit");
        require(_dumpBuyTx < 10, "Surpasses Tax Limit");

        pumpBuyTax = _pumpBuyTx;
        pumpSellTax = _pumpSellTx;
        dumpBuyTax = _dumpBuyTx;
        dumpSellTax = _dumpSellTx;
    }

    function updatedAutoTax() internal {
        uint256 currentPrice = checkCurrentPrice();

        if (currentPrice > lastTokenPrice) {
            if (customTaxMode) {
                autoBuyTax = dumpBuyTax;
                autoSellTax = dumpSellTax;
                pumping = false;
                emit Pumping(false);
            } else {
                autoBuyTax = 5;
                autoSellTax = 10;
                pumping = false;
                emit Pumping(false);
            }
        } else {
            if (customTaxMode) {
                autoBuyTax = pumpBuyTax;
                autoSellTax = pumpSellTax;
                pumping = true;
                emit Pumping(true);
            } else {
                autoBuyTax = 1;
                autoSellTax = 5;
                pumping = true;
                emit Pumping(true);
            }
        }

        lastTokenPrice = currentPrice;
        lastPriceCheckTimeStamp = block.timestamp;
    }

    function checkCurrentPrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = stableCoin; // Stablecoin
        path[1] = uniswapV2Router.WETH();

        uint256 wethOut = uniswapV2Router.getAmountsOut(1000000, path)[1];

        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uint256 currentPrice = uniswapV2Router.getAmountsOut(wethOut, path)[1];

        return currentPrice;
    }
}

// Interfaces
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint256);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint256 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint256 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint256 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint256 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
