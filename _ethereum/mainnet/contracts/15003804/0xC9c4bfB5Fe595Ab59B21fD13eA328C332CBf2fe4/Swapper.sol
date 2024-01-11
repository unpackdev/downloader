// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Governable.sol";
import "./ISwapper.sol";
import "./IExchange.sol";
import "./DataTypes.sol";

/**
 * @notice Swapper contract
 * This contract encapsulates DEXes and use them to perform swaps using the best trade path as possible
 */
contract Swapper is ISwapper, Governable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice List of the supported exchanges
     */
    EnumerableSet.AddressSet private allExchanges;

    /**
     * @notice List of the exchanges to loop over when getting best paths
     */
    EnumerableSet.AddressSet private mainExchanges;

    /**
     * @notice Mapping of exchanges' addresses by type
     */
    mapping(DataTypes.ExchangeType => address) public addressOf;

    /**
     * @notice Default swap routings
     * @dev Used to save gas by using a preset routing instead of looking for the best
     */
    mapping(bytes => bytes) public defaultRoutings;

    /**
     * @notice The oracle contract
     * @dev This is used to set acceptable slippage parameters
     */
    IOracle public override oracle;

    /**
     * @notice Max slippage acceptable
     * @dev Use 18 decimals (e.g. 0.2e18 = 20%)
     */
    uint256 public override maxSlippage;

    /// @notice Emitted when an exchange is added
    event ExchangeUpdated(
        DataTypes.ExchangeType indexed exchangeType,
        address indexed oldExchange,
        address indexed newExchange
    );

    /// @notice Emitted when an exchanges to loop over are updated
    event ExchangeAsMainUpdated(DataTypes.ExchangeType indexed exchangeType, bool isMain);

    /// @notice Emitted when the oracle is updated
    event OracleUpdated(IOracle indexed oldOracle, IOracle indexed newOracle);

    /// @notice Emitted when the max slippage is updated
    event MaxSlippageUpdated(uint256 oldMaxSlippage, uint256 newMaxSlippage);

    /// @notice Emitted when exact-input swap is executed
    event SwapExactInput(
        IExchange indexed exchange,
        bytes path,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice Emitted when exact-output swap is executed
    event SwapExactOutput(
        IExchange indexed exchange,
        bytes path,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountInMax,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice Emitted when default routing is updated
    event DefaultRoutingUpdated(bytes key, bytes oldRouting, bytes newRouting);

    constructor(IOracle oracle_, uint256 maxSlippage_) {
        oracle = oracle_;
        maxSlippage = maxSlippage_;
    }

    /// @inheritdoc ISwapper
    function getBestAmountIn(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    )
        public
        returns (
            uint256 _amountInMax,
            IExchange _exchange,
            bytes memory _path
        )
    {
        _amountInMax = (oracle.quote(tokenOut_, tokenIn_, amountOut_) * (1e18 + maxSlippage)) / 1e18;

        // 1. Return default routing if any
        bytes memory _defaultRouting = defaultRoutings[
            abi.encodePacked(DataTypes.SwapType.EXACT_OUTPUT, tokenIn_, tokenOut_)
        ];
        if (_defaultRouting.length > 0) {
            DataTypes.ExchangeType _exchangeType;
            (_exchangeType, _path) = abi.decode(_defaultRouting, (DataTypes.ExchangeType, bytes));
            return (_amountInMax, IExchange(addressOf[_exchangeType]), _path);
        }

        // 2. Look for the best routing
        uint256 _amountIn = type(uint256).max;
        uint256 _len = mainExchanges.length();
        for (uint256 i; i < _len; ++i) {
            IExchange _iExchange = IExchange(mainExchanges.at(i));
            (uint256 _iAmountIn, bytes memory _iPath) = _iExchange.getBestAmountIn(tokenIn_, tokenOut_, amountOut_);
            if (_iAmountIn > 0 && _iAmountIn < _amountIn && _iAmountIn <= _amountInMax) {
                _amountIn = _iAmountIn;
                _exchange = _iExchange;
                _path = _iPath;
            }
        }
        require(_path.length > 0, "no-routing-found");
    }

    /// @inheritdoc ISwapper
    function getBestAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    )
        public
        returns (
            uint256 _amountOutMin,
            IExchange _exchange,
            bytes memory _path
        )
    {
        _amountOutMin = (oracle.quote(tokenIn_, tokenOut_, amountIn_) * (1e18 - maxSlippage)) / 1e18;

        // 1. Return default routing if any
        bytes memory _defaultRouting = defaultRoutings[
            abi.encodePacked(DataTypes.SwapType.EXACT_INPUT, tokenIn_, tokenOut_)
        ];
        if (_defaultRouting.length > 0) {
            DataTypes.ExchangeType _exchangeType;
            (_exchangeType, _path) = abi.decode(_defaultRouting, (DataTypes.ExchangeType, bytes));
            return (_amountOutMin, IExchange(addressOf[_exchangeType]), _path);
        }

        // 2. Look for the best routing
        uint256 _amountOut;
        uint256 _len = mainExchanges.length();
        for (uint256 i; i < _len; ++i) {
            IExchange _iExchange = IExchange(mainExchanges.at(i));
            (uint256 _iAmountOut, bytes memory _iPath) = _iExchange.getBestAmountOut(tokenIn_, tokenOut_, amountIn_);
            if (_iAmountOut > _amountOut && _iAmountOut >= _amountOutMin) {
                _amountOut = _iAmountOut;
                _exchange = _iExchange;
                _path = _iPath;
            }
        }

        require(_path.length > 0, "no-routing-found");
    }

    /// @inheritdoc ISwapper
    function getAllExchanges() external view override returns (address[] memory) {
        return allExchanges.values();
    }

    /// @inheritdoc ISwapper
    function getMainExchanges() external view override returns (address[] memory) {
        return mainExchanges.values();
    }

    /// @inheritdoc ISwapper
    function swapExactInput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        address receiver_
    ) external returns (uint256 _amountOut) {
        (uint256 _amountOutMin, IExchange _exchange, bytes memory _path) = getBestAmountOut(
            tokenIn_,
            tokenOut_,
            amountIn_
        );
        return _swapExactInput(tokenIn_, tokenOut_, amountIn_, receiver_, _amountOutMin, _exchange, _path);
    }

    /// @inheritdoc ISwapper
    function swapExactInputWithDefaultRouting(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address receiver_
    ) external returns (uint256 _amountOut) {
        bytes memory _defaultRouting = defaultRoutings[
            abi.encodePacked(DataTypes.SwapType.EXACT_INPUT, tokenIn_, tokenOut_)
        ];
        require(_defaultRouting.length > 0, "no-default-routing-found");
        (DataTypes.ExchangeType _exchangeType, bytes memory _path) = abi.decode(
            _defaultRouting,
            (DataTypes.ExchangeType, bytes)
        );
        return
            _swapExactInput(
                tokenIn_,
                tokenOut_,
                amountIn_,
                receiver_,
                amountOutMin_,
                IExchange(addressOf[_exchangeType]),
                _path
            );
    }

    /// @inheritdoc ISwapper
    function swapExactOutput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_,
        address receiver_
    ) external returns (uint256 _amountIn) {
        (uint256 _amountInMax, IExchange _exchange, bytes memory _path) = getBestAmountIn(
            tokenIn_,
            tokenOut_,
            amountOut_
        );
        return _swapExactOutput(tokenIn_, tokenOut_, amountOut_, receiver_, _amountInMax, _exchange, _path);
    }

    /// @inheritdoc ISwapper
    function swapExactOutputWithDefaultRouting(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address receiver_
    ) external returns (uint256 _amountIn) {
        bytes memory _defaultRouting = defaultRoutings[
            abi.encodePacked(DataTypes.SwapType.EXACT_OUTPUT, tokenIn_, tokenOut_)
        ];
        require(_defaultRouting.length > 0, "no-default-routing-found");
        (DataTypes.ExchangeType _exchangeType, bytes memory _path) = abi.decode(
            _defaultRouting,
            (DataTypes.ExchangeType, bytes)
        );
        return
            _swapExactOutput(
                tokenIn_,
                tokenOut_,
                amountOut_,
                receiver_,
                amountInMax_,
                IExchange(addressOf[_exchangeType]),
                _path
            );
    }

    /**
     * @notice Add or update exchange
     * @dev Use null `exchange_` for removal
     */
    function setExchange(DataTypes.ExchangeType type_, address exchange_) external onlyGovernor {
        address _currentExchange = addressOf[type_];

        if (_currentExchange == address(0)) {
            // Adding
            require(allExchanges.add(exchange_), "exchange-exists");
            require(mainExchanges.add(exchange_), "main-exchange-exists");
            addressOf[type_] = exchange_;
        } else if (exchange_ == address(0)) {
            // Removing
            require(allExchanges.remove(_currentExchange), "exchange-does-not-exist");
            if (mainExchanges.contains(_currentExchange)) {
                mainExchanges.remove(_currentExchange);
            }
            delete addressOf[type_];
        } else {
            // Updating
            if (mainExchanges.contains(_currentExchange)) {
                mainExchanges.remove(_currentExchange);
            }
            require(allExchanges.remove(_currentExchange), "exchange-does-not-exist");
            require(allExchanges.add(exchange_), "exchange-exists");
            require(mainExchanges.add(exchange_), "main-exchange-exists");
            addressOf[type_] = exchange_;
        }
        emit ExchangeUpdated(type_, _currentExchange, exchange_);
    }

    /**
     * @notice Toggle exchange as main
     */
    function toggleExchangeAsMain(DataTypes.ExchangeType type_) public onlyGovernor {
        address _address = addressOf[type_];
        require(_address != address(0), "exchange-does-not-exist");
        if (mainExchanges.contains(_address)) {
            mainExchanges.remove(_address);
            emit ExchangeAsMainUpdated(type_, false);
        } else {
            mainExchanges.add(_address);
            emit ExchangeAsMainUpdated(type_, true);
        }
    }

    /**
     * @notice Update max slippage
     */
    function updateMaxSlippage(uint256 maxSlippage_) external onlyGovernor {
        require(maxSlippage_ <= 1e18, "max-slippage-gt-100%");
        emit MaxSlippageUpdated(maxSlippage, maxSlippage_);
        maxSlippage = maxSlippage_;
    }

    /**
     * @notice Update oracle contract
     */
    function updateOracle(IOracle oracle_) external onlyGovernor {
        require(address(oracle_) != address(0), "address-is-null");
        emit OracleUpdated(oracle, oracle_);
        oracle = oracle_;
    }

    /**
     * @notice Set default routing
     * @dev Use empty `path_` for removal
     * @param swapType_ If the routing is related to `EXACT_INPUT` or `EXACT_OUTPUT`
     * @param tokenIn_ The swap in token
     * @param tokenOut_ The swap out token
     * @param exchange_ The type (i.e. protocol) of the exchange
     * @param path_ The swap path
     * @dev Use `abi.encodePacked(tokenA, poolFee1, tokenB, poolFee2, tokenC, ...)` for UniswapV3 exchange
     * @dev Use `abi.encode([tokenA, tokenB, tokenC, ...])` for UniswapV2-like exchanges
     */
    function setDefaultRouting(
        DataTypes.SwapType swapType_,
        address tokenIn_,
        address tokenOut_,
        DataTypes.ExchangeType exchange_,
        bytes calldata path_
    ) external onlyGovernor {
        bytes memory _key = abi.encodePacked(swapType_, tokenIn_, tokenOut_);
        bytes memory _currentRouting = defaultRoutings[_key];
        bytes memory _newRouting = abi.encode(exchange_, path_);
        if (path_.length == 0) {
            delete defaultRoutings[_key];
        } else {
            defaultRoutings[_key] = _newRouting;
        }
        emit DefaultRoutingUpdated(_key, _currentRouting, _newRouting);
    }

    /**
     * @notice Perform an exact input swap
     * @dev This code is reused by public/external functions
     */
    function _swapExactInput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        address receiver_,
        uint256 _amountOutMin,
        IExchange _exchange,
        bytes memory _path
    ) private returns (uint256 _amountOut) {
        IERC20(tokenIn_).safeTransferFrom(msg.sender, address(_exchange), amountIn_);
        _amountOut = _exchange.swapExactInput(_path, amountIn_, _amountOutMin, receiver_);
        emit SwapExactInput(_exchange, _path, tokenIn_, tokenOut_, amountIn_, _amountOut);
    }

    /**
     * @notice Perform an exact output swap
     * @dev This code is reused by public/external functions
     */
    function _swapExactOutput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_,
        address receiver_,
        uint256 _amountInMax,
        IExchange _exchange,
        bytes memory _path
    ) private returns (uint256 _amountIn) {
        IERC20(tokenIn_).safeTransferFrom(msg.sender, address(_exchange), _amountInMax);
        _amountIn = _exchange.swapExactOutput(_path, amountOut_, _amountInMax, msg.sender, receiver_);
        emit SwapExactOutput(_exchange, _path, tokenIn_, tokenOut_, _amountInMax, _amountIn, amountOut_);
    }
}
