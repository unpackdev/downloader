// https://eigenlabs.io
// https://t.me/Eigen_Labs

// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ERC20.sol";

pragma solidity ^0.8.19;

contract Paradox is Ownable, ERC20 {
    IUniswapV2Router02 public uniswapV2Router;
    uint256 public maxTxAmount;
    uint256 public buyTaxPercent = 25;
    uint256 public sellTaxPercent = 25;
    uint256 public minAmountToSwapTaxes;
    uint256 public maxWalletAmount;
    uint256 public launchedAt;
    bool public launchTax;
    bool public taxesEnabled = true;
    bool public limitsEnabled = true;

    bool inSwapAndLiq;
    bool public tradingAllowed = false;

    address public teamWallet;
    address public uniswapV2Pair;
    address public claimContract;

    mapping(address => bool) public _isExcludedFromFees;

    modifier lockTheSwap() {
        inSwapAndLiq = true;
        _;
        inSwapAndLiq = false;
    }

    constructor() ERC20("Paradox", "PRDX") {
        _mint(owner(), 100_000_000 * 10 ** 18);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        minAmountToSwapTaxes = (totalSupply() * 3) / 1000;
        maxWalletAmount = (totalSupply() * 2) / 100;
        maxTxAmount = totalSupply() / 100;

        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[teamWallet] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(_uniswapV2Pair)] = true;

        teamWallet = 0xA7413c9fca36E5c0Fdc8025Cc9D11D20fb551369;
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
            require(from == owner() || to == owner(), "Trading not active yet");
        }

        if (limitsEnabled) {
            if (
                !_isExcludedFromFees[to] &&
                from != claimContract &&
                from != owner()
            ) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "Max Wallet In Effect"
                );
                require(amount <= maxTxAmount, "Max Tx in effect");
            }
        }

        uint256 taxAmount;

        if (taxesEnabled) {
            if (launchTax) {
                getTax(block.number);
            }

            if (from == uniswapV2Pair) {
                if (!_isExcludedFromFees[to]) {
                    taxAmount = (amount * buyTaxPercent) / 100;
                }
            }

            if (to == uniswapV2Pair) {
                if (!_isExcludedFromFees[from]) {
                    taxAmount = (amount * sellTaxPercent) / 100;
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

        if (taxAmount > 0) {
            uint256 userAmount = amount - taxAmount;
            super._transfer(from, address(this), taxAmount);
            super._transfer(from, to, userAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function handleTax(uint256 _contractTokenBalance) internal lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(
            address(this),
            address(uniswapV2Router),
            _contractTokenBalance
        );

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _contractTokenBalance,
            0, // accept any amount of ETH
            path,
            teamWallet,
            block.timestamp
        );
    }

    function getTax(uint256 _block) internal {
        if (launchedAt >= _block) {
            buyTaxPercent = 75;
            sellTaxPercent = 75;
        } else if (launchedAt + 1 >= _block) {
            buyTaxPercent = 50;
            sellTaxPercent = 50;
        } else if (launchedAt + 3 >= _block) {
            buyTaxPercent = 25;
            sellTaxPercent = 25;
        } else if (launchedAt + 10 >= _block) {
            buyTaxPercent = 10;
            sellTaxPercent = 10;
        }
    }

    function changeTeamWallet(address _newTeamWallet) external onlyOwner {
        teamWallet = _newTeamWallet;
    }

    function removeLaunchTax(
        uint256 _newBuyTaxPercent,
        uint256 _newSellTaxPercent
    ) external onlyOwner {
        require(
            _newBuyTaxPercent < 10 && _newSellTaxPercent < 10,
            "Cannot set taxes above 10"
        );
        buyTaxPercent = _newBuyTaxPercent;
        sellTaxPercent = _newSellTaxPercent;
        launchTax = false;
    }

    function excludeFromFees(
        address _address,
        bool _isExcluded
    ) external onlyOwner {
        _isExcludedFromFees[_address] = _isExcluded;
    }

    function updateMaxWalletAmount(
        uint256 newMaxWalletAmount
    ) external onlyOwner {
        maxWalletAmount = newMaxWalletAmount;
    }

    function updateMaxTxAmount(uint256 _newAmount) external onlyOwner {
        maxTxAmount = _newAmount;
    }

    function changeMinAmountToSwapTaxes(
        uint256 newMinAmount
    ) external onlyOwner {
        require(newMinAmount > 0, "Cannot set to zero");
        minAmountToSwapTaxes = newMinAmount;
    }

    function enableTaxes(bool _enable) external onlyOwner {
        taxesEnabled = _enable;
    }

    function activate() external onlyOwner {
        require(!tradingAllowed, "Trading not paused");
        tradingAllowed = true;
        launchedAt = block.number;
        launchTax = true;
    }

    function toggleLimits(bool _limitsEnabed) external onlyOwner {
        limitsEnabled = _limitsEnabed;
    }

    function updateClaimContract(address _newClaimContract) external onlyOwner {
        claimContract = _newClaimContract;
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

    function decimals() external pure returns (uint8);

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
        uint8 v,
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
        uint8 v,
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
        uint8 v,
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
        uint8 v,
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
