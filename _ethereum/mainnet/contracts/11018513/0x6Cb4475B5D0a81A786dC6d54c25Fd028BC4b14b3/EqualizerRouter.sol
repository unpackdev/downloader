/**
 *Submitted for verification at Etherscan.io on 2020-09-28
*/

// File: @openzeppelin/contracts/math/Math.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    // SMARTXXX: function feeTo() external view returns (address);
    // SMARTXXX: function feeToSetter() external view returns (address);
    function feeInfoSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    // SMARTXXX: function setFeeTo(address) external;
    function setFeeInfo(address, uint32, uint32) external;
    // SMARTXXX: function setFeeToSetter(address) external;
    function setFeeInfoSetter(address) external;

    // SMARTXXX: fee info getter
    function getFeeInfo() external view returns (address, uint32, uint32);
}

// File: contracts/uniswapv2/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts/uniswapv2/interfaces/IUniswapV2ERC20.sol

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/uniswapv2/libraries/SafeMath.sol

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: contracts/uniswapv2/libraries/UniswapV2Library.sol

pragma solidity >=0.5.0;



library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'1c879dcd3af04306445addd2c308bd4d26010c7ca84c959c3564d4f6957ab20c' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/IEqualizer.sol

pragma solidity >=0.5.0;

interface IEqualizer {
    function getAPY(address token0, address token1) external view returns (uint256);

    function getPoolWeight(address token0, address token1) external view returns (uint256);

    function getPoolAndUserInfo(address token0, address token1, address user) external view returns (
        uint256 lastAllocPoint,
        uint256 currentAllocPoint,
        uint256 userInfoAmount,
        uint256 pending,
        uint256 allocPointGain
    );

    function getRoundLengthAndLastEndBlock() external view returns (
        uint256 length,
        uint256 endBlock
    );

    function rounds(uint256 index) external view returns (
        uint256 allocPoint,
        uint256 totalAllocPoint,
        uint256 endBlock
    );
}

// File: contracts/EqualizerRouter.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract EqualizerRouter {

    IUniswapV2Factory public factory;
    IEqualizer public master;
    address public weth;

    uint256 constant REQUEST_POOL_LIMIT = 50;

    constructor(
        IUniswapV2Factory _factory,
        IEqualizer _master,
        address _weth
    ) public {
        factory = _factory;
        master = _master;
        weth = _weth;
    }

    function getMyPairs()
    public
    virtual
    view
    returns (address[] memory addresses)
    {
        uint256 length;
        for (uint256 i = 0; i < factory.allPairsLength(); i++) {
            address pair = factory.allPairs(i);
            if (IUniswapV2Pair(pair).balanceOf(msg.sender) > 0) {
                length++;
            }
        }
        addresses = new address[](length);
        length = 0;
        for (uint256 i = 0; i < factory.allPairsLength(); i++) {
            address pair = factory.allPairs(i);
            if (IUniswapV2Pair(pair).balanceOf(msg.sender) > 0) {
                addresses[length++] = pair;
            }
        }
    }

    function getLiquidityInfo(address pair)
    public
    virtual
    view
    returns (
        address token0,
        address token1,
        uint256 tokens,
        uint256 totalSupply,
        uint256 reserve0,
        uint256 reserve1,
        string memory token0Symbol,
        string memory token1Symbol,
        uint256 token0Decimals,
        uint256 token1Decimals
    )
    {
        IUniswapV2Pair p = IUniswapV2Pair(pair);
        token0 = p.token0();
        token1 = p.token1();
        token0Symbol = IERC20Uniswap(token0).symbol();
        token1Symbol = IERC20Uniswap(token1).symbol();
        token0Decimals = IERC20Uniswap(token0).decimals();
        token1Decimals = IERC20Uniswap(token1).decimals();
        tokens = p.balanceOf(msg.sender);
        totalSupply = p.totalSupply();
        (reserve0, reserve1) = UniswapV2Library.getReserves(
            address(factory),
            token0,
            token1
        );
    }

    function getPairInfos(uint256 page)
    external
    view
    returns (
        address[REQUEST_POOL_LIMIT] memory lpTokens,
        address[REQUEST_POOL_LIMIT] memory token0Address,
        address[REQUEST_POOL_LIMIT] memory token1Address,
        bytes32[REQUEST_POOL_LIMIT] memory token0Symbols,
        bytes32[REQUEST_POOL_LIMIT] memory token1Symbols
    )
    {
        uint256 position = page * REQUEST_POOL_LIMIT;
        uint256 end = Math.min(position + REQUEST_POOL_LIMIT, factory.allPairsLength());
        uint8 i = 0;
        for (; position < end; position++) {
            lpTokens[i] = factory.allPairs(position);
            IUniswapV2Pair pair = IUniswapV2Pair(lpTokens[i]);
            token0Address[i] = pair.token0();
            token1Address[i] = pair.token1();
            token0Symbols[i] = stringToBytes32(IUniswapV2ERC20(pair.token0()).symbol());
            token1Symbols[i] = stringToBytes32(IUniswapV2ERC20(pair.token1()).symbol());
            i++;
        }
    }

    function getPairInfo(address pairAddress)
    external
    view
    returns (
        address token0,
        address token1,
        bool token0EthRoute,
        bool token1EthRoute,
        bytes32 token0Symbol,
        bytes32 token1Symbol
    )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        require(factory.getPair(pair.token0(), pair.token1()) != address(0x0), "lp token not exist");

        // token0
        token0 = pair.token0();
        IUniswapV2ERC20 token0ERC = IUniswapV2ERC20(token0);
        token0Symbol = stringToBytes32(token0ERC.symbol());
        token0EthRoute = (token0 == weth || token1 == weth) ||
        factory.getPair(token0, weth) != address(0x0);
        // token1
        token1 = pair.token1();
        IUniswapV2ERC20 token1ERC = IUniswapV2ERC20(token1);
        token1Symbol = stringToBytes32(token1ERC.symbol());
        token1EthRoute = (token0 == weth || token1 == weth) ||
        factory.getPair(token1, weth) != address(0x0);
    }

    function getPoolInfos(uint256 page)
    external
    view
    returns (
        uint256[REQUEST_POOL_LIMIT] memory lpTokenBalances,
        uint256[REQUEST_POOL_LIMIT] memory allocPoints,
        uint256[REQUEST_POOL_LIMIT] memory userInfoAmounts,
        uint256[REQUEST_POOL_LIMIT] memory pendingSmarts,
        uint256[REQUEST_POOL_LIMIT] memory allocPointGains
    )
    {
        uint256 position = page * REQUEST_POOL_LIMIT;
        uint256 end = Math.min(position + REQUEST_POOL_LIMIT, factory.allPairsLength());
        uint8 i = 0;
        for (; position < end; position++) {
            IUniswapV2Pair pair = IUniswapV2Pair(factory.allPairs(position));
            lpTokenBalances[i] = pair.balanceOf(msg.sender);
            (allocPoints[i], , userInfoAmounts[i], pendingSmarts[i], allocPointGains[i]) = master
        .getPoolAndUserInfo(pair.token0(), pair.token1(), msg.sender);
            i++;
        }
    }

    function getPoolInfo(address pairAddress)
    external
    view
    returns (
        uint256 userInfoAmount,
        uint256 pending,
        uint256 totalStaked,
        uint256 lastAllocPoint,
        uint256 lastTotalAllocPoint,
        uint256 currentAllocPoint,
        uint256 currentTotalAllocPoint
    )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        totalStaked = pair.balanceOf(address(master));
        (lastAllocPoint, currentAllocPoint, userInfoAmount, pending,) = master.getPoolAndUserInfo(
            pair.token0(),
            pair.token1(),
            msg.sender
        );

        (uint256 length,) = master.getRoundLengthAndLastEndBlock();
        lastTotalAllocPoint = 0;
        if (length > 1) {
            (, lastTotalAllocPoint,) = master.rounds(length - 2);
        }
        (, currentTotalAllocPoint,) = master.rounds(length - 1);
    }

    function getAPYs(uint256 page)
    external
    view
    returns (uint256[REQUEST_POOL_LIMIT] memory apys)
    {
        uint256 position = page * REQUEST_POOL_LIMIT;
        uint256 end = Math.min(position + REQUEST_POOL_LIMIT, factory.allPairsLength());
        uint8 i = 0;
        for (; position < end; position++) {
            apys[i] = getAPY(factory.allPairs(position));
            i++;
        }
    }

    function getAPY(address pairAddress) public view returns (uint256 apy) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        apy = master.getAPY(pair.token0(), pair.token1());
    }

    function stringToBytes32(string memory source)
    public
    pure
    returns (bytes32 result)
    {
        bytes memory data = bytes(source);
        if (data.length == 0) {
            return 0x0;
        }
        /* solium-disable-next-line */
        assembly {
            result := mload(add(source, 32))
        }
    }
}