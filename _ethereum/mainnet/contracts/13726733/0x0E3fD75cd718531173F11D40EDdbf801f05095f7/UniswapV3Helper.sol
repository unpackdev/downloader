pragma solidity 0.7.6;
pragma abicoder v2;

import "./OracleLibrary.sol";
import "./Ownable.sol";

contract UniswapV3Helper is Ownable {
    address public immutable uniswapV3Factory;
    uint32 public periodForAvgPrice;

    bytes4 public constant SYMBOL_SELECTOR = bytes4(keccak256("symbol()"));
    bytes4 public constant DECIMALS_SELECTOR = bytes4(keccak256("decimals()"));
    bytes4 public constant GET_POOL_SELECTOR = bytes4(keccak256("getPool(address,address,uint24)"));

    struct PriceData {
        address tokenA;
        address tokenB;
        uint24 fee;
    }

    struct Price {
        uint256 price;
        bool success;
    }

    constructor(address _factory, uint32 _periodForAvgPrice) {
        bytes4 selector = bytes4(keccak256("feeAmountTickSpacing(uint24)"));
        (bool success, ) = _factory.staticcall(abi.encode(selector, 500));
        require(success, "UniswapV3Oracle: invalid factory");
        require(_periodForAvgPrice > 0, "UniswapV3Oracle: invalid periodForAvgPrice");

        uniswapV3Factory = _factory;
        periodForAvgPrice = _periodForAvgPrice;
    }

    function changePeriodForAvgPrice(uint32 _period) external onlyOwner {
        periodForAvgPrice = _period;
    }

    function tokensSymbols(address[] memory _tokens) public view returns (string[] memory symbols) {
        uint256 n = _tokens.length;
        symbols = new string[](n);

        for (uint256 i = 0; i < n; i++) {
            (bool success, bytes memory data) = _tokens[i].staticcall(abi.encode(SYMBOL_SELECTOR));
            symbols[i] = success ? abi.decode(data, (string)) : "";
        }
    }

    function getPrices(PriceData[] calldata _data) public view returns (Price[] memory prices) {
        uint256 n = _data.length;
        prices = new Price[](n);

        for (uint256 i = 0; i < n; i++) {
            (prices[i].success, prices[i].price) = getPrice(_data[i].tokenA, _data[i].tokenB, _data[i].fee);
        }
    }

    function getPrice(address _tokenA, address _tokenB, uint24 _fee) public view returns (bool success, uint256 price) {
        bytes memory data;

        (success, data) = _tokenA.staticcall(abi.encode(DECIMALS_SELECTOR));
        if (!success) return (false, 0);

        uint256 decimals = abi.decode(data, (uint256));
        uint256 baseAmountA = 10 ** decimals;

        if (_tokenA == _tokenB) return (true, baseAmountA);

        address pool = resolvePool(_tokenA, _tokenB, _fee);
        if(pool == address(0)) return (false, 0);

        // Number of seconds in the past to start calculating time-weighted average
        (int24 arithmeticMeanTick, ) = OracleLibrary.consult(pool, periodForAvgPrice);
        price = OracleLibrary.getQuoteAtTick(arithmeticMeanTick, uint128(baseAmountA), _tokenA, _tokenB);
    }

    function resolvePool(address _tokenA, address _tokenB, uint24 _fee) public view returns (address pool) {
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

        (
            bool success,
            bytes memory data
        ) = uniswapV3Factory.staticcall(abi.encodeWithSelector(GET_POOL_SELECTOR, token0, token1, _fee));

        return success ? abi.decode(data, (address)) : address(0);
    }
}
