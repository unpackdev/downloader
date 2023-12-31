// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: back/batchFindPool.sol


pragma solidity ^0.8.0;



contract FindPoolAndReserve  {
    struct Input {
        address uniswapFactory ;uint256 start ;uint256 end ;
    }
    function getTokenPairs(Input memory input) view  public  returns (
        address[] memory,address[] memory,address[] memory,
        uint256[] memory,uint256[] memory,uint256[] memory
        ){
        uint256 pairCount = input.end - input.start;
        address[] memory pairs = new address[](pairCount);
        address[] memory toeknAs = new address[](pairCount);
        address[] memory toeknBs = new address[](pairCount);
        uint256[] memory reserveA = new uint256[](pairCount);
        uint256[] memory reserveB = new uint256[](pairCount);
        uint256[] memory blockTimestampLast = new uint256[](pairCount);

        for (uint256 i = input.start ; i < input.end ; i++) {
            pairs[i] = IUniswapV2Factory(input.uniswapFactory).allPairs(i);
            (toeknAs[i], toeknBs[i]) = IUniswapV2Pair(pairs[i]).token0() < IUniswapV2Pair(pairs[i]).token1()
            ? (IUniswapV2Pair(pairs[i]).token0(), IUniswapV2Pair(pairs[i]).token1())
            : (IUniswapV2Pair(pairs[i]).token1(), IUniswapV2Pair(pairs[i]).token0());
             (reserveA[i], reserveB[i],blockTimestampLast[i] ) = IUniswapV2Pair(pairs[i]).getReserves();
        }
        return (pairs,toeknAs,toeknBs,reserveA,reserveB,blockTimestampLast);
    }
}