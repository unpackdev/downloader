// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./HelixLibrary.sol";

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2OracleLibrary.sol";
import "./FixedPoint.sol";

// Used for creating, updating, and consulting fixed window, token pair price oracles
contract OracleFactory is Initializable, OwnableUpgradeable {
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    struct Oracle {
        address token0;
        address token1;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }
    
    /// Contract approved to create new oracle pairs
    address public factory;

    /// Minimum time between updates in seconds, 86400 == 1 day
    uint256 public period;

    /// Bidirection mapping of token address pair to an Oracle struct
    /// i.e. token0 => token1 => Oracle == token1 => token0 => Oracle
    mapping(address => mapping(address => Oracle)) public oracles;

    // Emitted when a new oracle is created
    event Create(
        address indexed pair,
        address indexed token0,
        address indexed token1,
        address creator,
        uint256 price0CumulativeLast,
        uint256 price1CumulativeLast
    );
    
    // Emitted when an existing oracle is updated
    event Update(
        address indexed pair,
        address indexed token0, 
        address indexed token1, 
        address updater,
        uint256 price0Cumulative,
        uint256 price1Cumulative,
        uint256 reserve0,
        uint256 reserve1
    );

    // Emitted when the owner sets a period
    event SetPeriod(
        address indexed setter,
        uint256 period
    );

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "OracleFactory: zero address");
        _;
    }

    function initialize(address _factory) external initializer {
        __Ownable_init();
        factory = _factory;
        period = 24 hours;
    }

    /// Create a new oracle for _token0 and _token1
    function create(address _token0, address _token1)
        external 
        onlyValidAddress(_token0)
        onlyValidAddress(_token1)
    {
        require(msg.sender == factory || msg.sender == owner(), "OracleFactory: invalid caller");
        require(_token0 != _token1, "OracleFactory: identical addresses");
        require(
            !oracleExists(_token0, _token1), 
            "OracleFactory: already created"
        );

        // Get the pair instance
        IUniswapV2Pair pair = IUniswapV2Pair(HelixLibrary.pairFor(factory, _token0, _token1));

        // Create the new oracle struct
        Oracle memory oracle;
        oracle.token0 = _token0;
        oracle.token1 = _token1;
        oracle.price0CumulativeLast = pair.price0CumulativeLast(); 
        oracle.price1CumulativeLast = pair.price1CumulativeLast();

        // Populate the mapping in both directions 
        oracles[_token0][_token1] = oracle;
        oracles[_token1][_token0] = oracle;

        emit Create(
            address(pair),
            _token0,
            _token1,
            msg.sender,
            pair.price0CumulativeLast(),
            pair.price1CumulativeLast()
        );
    }

    /// Update the prices of _token0 and _token1
    function update(address _token0, address _token1) external {
        Oracle storage oracle = _getOracle(_token0, _token1);
        IUniswapV2Pair pair = IUniswapV2Pair(HelixLibrary.pairFor(factory, oracle.token0, oracle.token1));

        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "OracleFactory: no reserves in pair");
 
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - oracle.blockTimestampLast;

        if (timeElapsed > period) {
            oracle.price0Average = _getAveragePrice(price0Cumulative, oracle.price0CumulativeLast, timeElapsed);
            oracle.price1Average = _getAveragePrice(price1Cumulative, oracle.price1CumulativeLast, timeElapsed);
            oracle.price0CumulativeLast = price0Cumulative;
            oracle.price1CumulativeLast = price1Cumulative;
            oracle.blockTimestampLast = blockTimestamp;
        } 
    
        emit Update(
            address(pair),
            _token0,
            _token1,
            msg.sender,
            price0Cumulative,
            price1Cumulative,
            reserve0,
            reserve1
        );
    }

    /// Called by the owner to set a new period
    function setPeriod(uint256 _period) external onlyOwner {
        period = _period;
        emit SetPeriod(msg.sender, _period);
    }

    /// Get the amountOut of _tokenOut equivalent in value to _amountIn of _tokenIn
    /// Will return 0 before update has been called successfully for the first time
    function consult(address _tokenIn, uint256 _amountIn, address _tokenOut) 
        external 
        view 
        returns (uint256 amountOut) 
    {
        if (oracleExists(_tokenIn, _tokenOut)) {
            Oracle memory oracle = _getOracle(_tokenIn, _tokenOut);
            if (_tokenIn == oracle.token0) {
                amountOut = oracle.price0Average.mul(_amountIn).decode144();
            } else {
                require(_tokenIn == oracle.token1, "Oracle: invalid token");
                amountOut = oracle.price1Average.mul(_amountIn).decode144();
            }
        } else {
            amountOut = _amountIn;
        }
    } 

    /// Return the oracle defined by _token0 and _token1
    function getOracle(address _token0, address _token1) external view returns (Oracle memory) {
        return _getOracle(_token0, _token1);
    }

    /// Return whether enough time has passed to update the oracle defined by _token0 and _token1
    function canUpdate(address _token0, address _token1) external view returns (bool) {
        uint32 blockTimestamp = _getBlockTimestamp();

        Oracle memory oracle = _getOracle(_token0, _token1);
        uint32 timeElapsed = blockTimestamp - oracle.blockTimestampLast;

        return timeElapsed >= period;
    }
    
    /// Return true if the oracle defined by _token0 and _token1 has been created and false otherwise
    function oracleExists(address _token0, address _token1) public view returns (bool) {
        // Its enough to check that token0 doesn't equal address 0 since an 
        // oracle can't be created with a zero address
        return oracles[_token0][_token1].token0 != address(0);
    }

    // Return the Oracle struct
    function _getOracle(address _token0, address _token1) private view returns (Oracle storage) {
        require(oracleExists(_token0, _token1), "OracleFactory: not created");
        return oracles[_token0][_token1];
    }

    // Helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function _getBlockTimestamp() private view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // Return the average price between _curr and _prev prices over the _elapsed duration
    function _getAveragePrice(uint256 _curr, uint256 _prev, uint32 _elapsed) 
        private 
        pure 
        returns (FixedPoint.uq112x112 memory)
    {
        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        return FixedPoint.uq112x112(uint224((_curr - _prev) / _elapsed));
    }
}
