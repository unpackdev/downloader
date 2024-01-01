pragma solidity 0.8.9;

import "./VRFV2WrapperConsumerBase.sol";

//SPDX-License-Identifier: UNLICENCED

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);

        return a % b;
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

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
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

// import "./VRFCoordinatorV2Interface.sol";
// import "./VRFConsumerBaseV2.sol";

contract RaffleTest is ERC20, Ownable, VRFV2WrapperConsumerBase {
    using SafeMath for uint256;

    uint8 public constant RAFFLE_STATE_ACTIVE = 1;
    uint8 public constant RAFFLE_STATE_DRAWING = 2;
    uint8 public constant RAFFLE_STATE_COMPLETED = 3;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public treasuryWallet;

    bool private swapping;
    bool private payout;

    uint256 public reflectionPool;
    uint256 public prizePool;

    uint256 public prizePoolTokens;

    uint256 public prizePoolShare = 70;
    uint256 public treasuryShare = 30;

    uint256 public maxWallet;
    uint256 public maxTransactionAmount;

    uint256 public maxSaleIncrement = 5;
    uint256 public saleIncrement;

    uint256 public tokensToSwap;
    uint256 public minSwapAmount = 10 ** 10;

    uint256 public deployedOn;

    /******************/

    struct RaffleRun {
        uint256 state;
        uint256[] randomWords;
        uint256 drawingAt;
        uint256 range;
        uint32 words;
        bool exists;
    }

    mapping(uint256 => RaffleRun) public raffles;
    uint256 public rafflesLength;

    mapping(uint256 => uint256) public vrfRequests;

    // chainlink data
    uint32 public baseCallbackGasLimit = 100000;
    uint32 public callbackGasLimitIncrement = 16000;
    uint16 public requestConfirmations = 3;

    /******************/

    mapping(address => bool) public isExcludedFromFees;

    mapping(address => bool) public isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event VRFRequestSent(
        uint256 indexed raffleId,
        uint256 indexed requestId,
        uint32 limit
    );

    event VRFRequestFulfilled(
        uint256 indexed raffleId,
        uint256 indexed requestId
    );

    constructor(
        address linkAddress,
        address linkWrapperAddress,
        address uniswapRouterAddress
    )
        ERC20("TestRa", "TR")
        VRFV2WrapperConsumerBase(linkAddress, linkWrapperAddress)
    {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            uniswapRouterAddress
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        excludeFromFees(owner(), true); // Owner address
        excludeFromFees(address(this), true); // CA
        excludeFromFees(address(0xdead), true); // Burn address

        excludeFromMaxTransaction(owner(), true); // Owner address
        excludeFromMaxTransaction(address(this), true); // CA
        excludeFromMaxTransaction(address(0xdead), true); // Burn address

        uint256 _totalSupply = 1000000000 * 10 ** 18;

        maxWallet = (_totalSupply * 2) / 100;
        maxTransactionAmount = (_totalSupply * 2) / 100;

        reflectionPool = (_totalSupply * 20) / 100;
        prizePoolTokens = (_totalSupply * 10) / 100;

        treasuryWallet = address(owner());

        // transfer the reflection pool to this contract
        _mint(address(this), reflectionPool + prizePoolTokens);

        // transfer remainder to owner
        _mint(msg.sender, _totalSupply - reflectionPool - prizePoolTokens);

        deployedOn = block.timestamp;
    }

    receive() external payable {}

    modifier onlyExistingRaffle(uint256 id) {
        require(raffles[id].exists, "onlyExistingRaffle");
        _;
    }

    modifier onlyRaffleWithState(uint256 id, uint256 state) {
        require(raffles[id].state == state, "onlyRaffleWithState");
        _;
    }

    function startRaffle(
        uint256 min,
        uint256 range,
        uint32 words
    ) external onlyOwner {
        RaffleRun storage raffle = raffles[rafflesLength];
        raffle.state = 1;
        raffle.exists = true;
        raffle.drawingAt = block.timestamp + min * 1 minutes;
        raffle.range = range;
        raffle.words = words;

        rafflesLength++;
    }

    function bumpRaffleDrawing(
        uint256 id
    ) external onlyRaffleWithState(id, RAFFLE_STATE_ACTIVE) {
        require(block.timestamp >= raffles[id].drawingAt, "draw");

        raffles[id].state = RAFFLE_STATE_DRAWING;

        uint32 _callbackLimit = baseCallbackGasLimit +
            raffles[id].words *
            callbackGasLimitIncrement;

        uint256 _requestId = requestRandomness(
            _callbackLimit,
            requestConfirmations,
            raffles[id].words
        );

        vrfRequests[_requestId] = id;

        emit VRFRequestSent(id, _requestId, _callbackLimit);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(
            raffles[vrfRequests[requestId]].state == RAFFLE_STATE_DRAWING,
            "state"
        );

        raffles[vrfRequests[requestId]].state = RAFFLE_STATE_COMPLETED;
        raffles[vrfRequests[requestId]].randomWords = randomWords;

        emit VRFRequestFulfilled(vrfRequests[requestId], requestId);
    }

    function getRandomNum(
        uint256 id,
        uint256 index
    )
        external
        view
        onlyRaffleWithState(id, RAFFLE_STATE_COMPLETED)
        returns (uint256)
    {
        return raffles[id].randomWords[index] % raffles[id].range;
    }

    function updateMinSwapAmount(uint256 newNum) external onlyOwner {
        minSwapAmount = newNum;
    }

    function updateVRFData(
        uint32 baseGasLimit,
        uint32 baseGasLimitIncrement,
        uint16 confirmations
    ) external onlyOwner {
        baseCallbackGasLimit = baseGasLimit;
        callbackGasLimitIncrement = baseGasLimitIncrement;
        requestConfirmations = confirmations;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 5) / 1000) / 1e18, "too low");
        maxWallet = newNum * (10 ** 18);
    }

    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    ) public onlyOwner {
        isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(pair != uniswapV2Pair, "remove");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // function updateMinTokenSwapAmount(uint256 newAmount) external onlyOwner {
    //     minTokenSwapAmount = newAmount;
    // }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (!swapping && !payout) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead)
            ) {
                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }

            if (!isExcludedFromFees[from] && !isExcludedFromFees[to]) {
                uint256 _fee = 0;

                // on sell
                if (automatedMarketMakerPairs[to]) {
                    _fee = amount.mul(getSellFee()).div(100);

                    // increase sale tax on each sell, up to a set maximum
                    if (saleIncrement < maxSaleIncrement) {
                        saleIncrement = saleIncrement + 1;
                    }

                    storeFee(from, _fee);
                    swapFeeForEther();
                }
                // on buy
                else if (automatedMarketMakerPairs[from]) {
                    _fee = amount.mul(getBuyFee()).div(100);

                    // reset sale tax increment
                    saleIncrement = 0;

                    storeFee(from, _fee);
                }

                amount -= _fee;
            }
        }

        super._transfer(from, to, amount);
    }

    function storeFee(address from, uint256 amount) private {
        tokensToSwap += amount;
        super._transfer(from, address(this), amount);
    }

    function swapFeeForEther() public {
        uint[] memory amounts = getAmountsOutForEth(tokensToSwap);

        if (amounts[1] >= minSwapAmount) {
            swapping = true;

            // swap prizePoolShare with Ether
            uint256 _initialETHBalance = address(this).balance;
            swapTokensForEth(tokensToSwap);
            uint256 _swappedAmount = address(this).balance.sub(
                _initialETHBalance
            );

            swapping = false;

            tokensToSwap = 0;

            uint256 _prizePoolShare = _swappedAmount.mul(prizePoolShare).div(
                100
            );
            uint256 _ownerShare = _swappedAmount.sub(_prizePoolShare);

            // split swapped amount to prize pool and owner
            prizePool = prizePool.add(_prizePoolShare);

            treasuryWallet.call{value: _ownerShare}("");
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function getAmountsOutForEth(
        uint256 tokens
    ) private view returns (uint[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint[] memory amounts = uniswapV2Router.getAmountsOut(tokens, path);

        return amounts;
    }

    function getBuyFee() public view returns (uint256) {
        if (block.timestamp - deployedOn <= 7 minutes) {
            return 45;
        }

        if (block.timestamp - deployedOn <= 14 minutes) {
            return 35;
        }

        if (block.timestamp - deployedOn <= 20 minutes) {
            return 15;
        }

        return 5;
    }

    function getSellFee() public view returns (uint256) {
        if (block.timestamp - deployedOn <= 7 minutes) {
            return 45;
        }

        if (block.timestamp - deployedOn <= 20 minutes) {
            return 25;
        }

        return 5 + saleIncrement;
    }

    function getRaffleRandomWords(
        uint256 id
    ) external view onlyExistingRaffle(id) returns (uint256[] memory words) {
        return raffles[id].randomWords;
    }
}
