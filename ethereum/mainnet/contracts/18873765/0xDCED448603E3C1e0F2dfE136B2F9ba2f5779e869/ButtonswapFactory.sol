// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "./IButtonswapFactory.sol";
import "./IButtonswapPair.sol";
import "./ButtonswapPair.sol";

contract ButtonswapFactory is IButtonswapFactory {
    /**
     * @inheritdoc IButtonswapFactory
     */
    address public feeTo;

    /**
     * @inheritdoc IButtonswapFactory
     */
    address public feeToSetter;

    /**
     * @inheritdoc IButtonswapFactory
     */
    mapping(address => mapping(address => address)) public getPair;

    /**
     * @inheritdoc IButtonswapFactory
     */
    address[] public allPairs;

    address internal lastToken0;

    address internal lastToken1;

    /**
     * @inheritdoc IButtonswapFactory
     */
    address public paramSetter;

    /**
     * @inheritdoc IButtonswapFactory
     */
    string public tokenName;

    /**
     * @inheritdoc IButtonswapFactory
     */
    string public tokenSymbol;

    /**
     * @dev The upper limit on what duration parameters can be set to.
     */
    uint32 public constant MAX_DURATION_BOUND = 12 weeks;

    /**
     * @dev The upper limit on what BPS denominated parameters can be set to.
     */
    uint16 public constant MAX_BPS_BOUND = 10_000;

    /**
     * @dev The lower limit on what the `movingAverageWindow` can be set to.
     */
    uint32 public constant MIN_MOVING_AVERAGE_WINDOW_BOUND = 1 seconds;

    /**
     * @dev The lower limit on what the `swappableReservoirGrowthWindow` can be set to.
     */
    uint32 public constant MIN_SWAPPABLE_RESERVOIR_GROWTH_WINDOW_BOUND = 1 seconds;

    /**
     * @inheritdoc IButtonswapFactory
     */
    uint32 public defaultMovingAverageWindow = 24 hours;

    /**
     * @inheritdoc IButtonswapFactory
     */
    uint16 public defaultMaxVolatilityBps = 700;

    /**
     * @inheritdoc IButtonswapFactory
     */
    uint32 public defaultMinTimelockDuration = 24 seconds;

    /**
     * @inheritdoc IButtonswapFactory
     */
    uint32 public defaultMaxTimelockDuration = 24 hours;

    /**
     * @inheritdoc IButtonswapFactory
     */
    uint16 public defaultMaxSwappableReservoirLimitBps = 500;

    /**
     * @inheritdoc IButtonswapFactory
     */
    uint32 public defaultSwappableReservoirGrowthWindow = 24 hours;

    /**
     * @inheritdoc IButtonswapFactory
     */
    bool public isCreationRestricted;

    /**
     * @inheritdoc IButtonswapFactory
     */
    address public isCreationRestrictedSetter;

    /**
     * @inheritdoc IButtonswapFactory
     */
    address public isPausedSetter;

    /**
     * @dev `feeTo` is not initialised during deployment, and must be set separately by a call to {setFeeTo}.
     * @param _feeToSetter The account that has the ability to set `feeToSetter` and `feeTo`
     * @param _isCreationRestrictedSetter The account that has the ability to set `isCreationRestrictedSetter` and `isCreationRestricted`
     * @param _isPausedSetter The account that has the ability to set `isPausedSetter` and `isPaused`
     * @param _paramSetter The account that has the ability to set `paramSetter`, default parameters, and current parameters on existing pairs
     * @param _tokenName The name of the ERC20 liquidity token
     * @param _tokenSymbol The symbol of the ERC20 liquidity token
     */
    constructor(
        address _feeToSetter,
        address _isCreationRestrictedSetter,
        address _isPausedSetter,
        address _paramSetter,
        string memory _tokenName,
        string memory _tokenSymbol
    ) {
        feeToSetter = _feeToSetter;
        isCreationRestrictedSetter = _isCreationRestrictedSetter;
        isPausedSetter = _isPausedSetter;
        paramSetter = _paramSetter;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function allPairsLength() external view returns (uint256 count) {
        count = allPairs.length;
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if (isCreationRestricted && msg.sender != isCreationRestrictedSetter) {
            revert Forbidden();
        }
        if (tokenA == tokenB) {
            revert TokenIdenticalAddress();
        }
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) {
            revert TokenZeroAddress();
        }
        // single check is sufficient
        if (getPair[token0][token1] != address(0)) {
            revert PairExists();
        }
        lastToken0 = token0;
        lastToken1 = token1;
        bytes memory bytecode = type(ButtonswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // Resetting lastToken0/lastToken1 to 0 to refund gas
        lastToken0 = address(0);
        lastToken1 = address(0);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setFeeTo(address _feeTo) external {
        if (msg.sender != feeToSetter) {
            revert Forbidden();
        }
        feeTo = _feeTo;
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setFeeToSetter(address _feeToSetter) external {
        if (msg.sender != feeToSetter) {
            revert Forbidden();
        }
        feeToSetter = _feeToSetter;
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setIsCreationRestricted(bool _isCreationRestricted) external {
        if (msg.sender != isCreationRestrictedSetter) {
            revert Forbidden();
        }
        isCreationRestricted = _isCreationRestricted;
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setIsCreationRestrictedSetter(address _isCreationRestrictedSetter) external {
        if (msg.sender != isCreationRestrictedSetter) {
            revert Forbidden();
        }
        isCreationRestrictedSetter = _isCreationRestrictedSetter;
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setIsPaused(address[] calldata pairs, bool isPausedNew) external {
        if (msg.sender != isPausedSetter) {
            revert Forbidden();
        }
        uint256 length = pairs.length;
        for (uint256 i; i < length; ++i) {
            IButtonswapPair(pairs[i]).setIsPaused(isPausedNew);
        }
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setIsPausedSetter(address _isPausedSetter) external {
        if (msg.sender != isPausedSetter) {
            revert Forbidden();
        }
        isPausedSetter = _isPausedSetter;
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setParamSetter(address _paramSetter) external {
        if (msg.sender != paramSetter) {
            revert Forbidden();
        }
        paramSetter = _paramSetter;
    }

    /**
     * @dev `movingAverageWindow` must be in interval [MIN_MOVING_AVERAGE_WINDOW_BOUND, MAX_DURATION_BOUND]
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#movingaveragewindow) for more detail.
     */
    function _validateNewMovingAverageWindow(uint32 newMovingAverageWindow) internal pure {
        if (newMovingAverageWindow < MIN_MOVING_AVERAGE_WINDOW_BOUND || newMovingAverageWindow > MAX_DURATION_BOUND) {
            revert InvalidParameter();
        }
    }

    /**
     * @dev `maxVolatilityBps` must be in interval [0, MAX_BPS_BOUND]
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#maxvolatilitybps) for more detail.
     */
    function _validateNewMaxVolatilityBps(uint16 newMaxVolatilityBps) internal pure {
        if (newMaxVolatilityBps > MAX_BPS_BOUND) {
            revert InvalidParameter();
        }
    }

    /**
     * @dev `minTimelockDuration` must be in interval [0, MAX_DURATION_BOUND]
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#mintimelockduration) for more detail.
     */
    function _validateNewMinTimelockDuration(uint32 newMinTimelockDuration) internal pure {
        if (newMinTimelockDuration > MAX_DURATION_BOUND) {
            revert InvalidParameter();
        }
    }

    /**
     * @dev `maxTimelockDuration` must be in interval [0, MAX_DURATION_BOUND]
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#maxtimelockduration) for more detail.
     */
    function _validateNewMaxTimelockDuration(uint32 newMaxTimelockDuration) internal pure {
        if (newMaxTimelockDuration > MAX_DURATION_BOUND) {
            revert InvalidParameter();
        }
    }

    /**
     * @dev `maxSwappableReservoirLimitBps` must be in interval [0, MAX_BPS_BOUND]
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#maxswappablereservoirlimitbps) for more detail.
     */
    function _validateNewMaxSwappableReservoirLimitBps(uint32 newMaxSwappableReservoirLimitBps) internal pure {
        if (newMaxSwappableReservoirLimitBps > MAX_BPS_BOUND) {
            revert InvalidParameter();
        }
    }

    /**
     * @dev `swappableReservoirGrowthWindow` must be in interval [MIN_SWAPPABLE_RESERVOIR_GROWTH_WINDOW_BOUND, MAX_DURATION_BOUND]
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#swappablereservoirgrowthwindow) for more detail.
     */
    function _validateNewSwappableReservoirGrowthWindow(uint32 newSwappableReservoirGrowthWindow) internal pure {
        if (
            newSwappableReservoirGrowthWindow < MIN_SWAPPABLE_RESERVOIR_GROWTH_WINDOW_BOUND
                || newSwappableReservoirGrowthWindow > MAX_DURATION_BOUND
        ) {
            revert InvalidParameter();
        }
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setDefaultParameters(
        uint32 newDefaultMovingAverageWindow,
        uint16 newDefaultMaxVolatilityBps,
        uint32 newDefaultMinTimelockDuration,
        uint32 newDefaultMaxTimelockDuration,
        uint16 newDefaultMaxSwappableReservoirLimitBps,
        uint32 newDefaultSwappableReservoirGrowthWindow
    ) external {
        if (msg.sender != paramSetter) {
            revert Forbidden();
        }
        _validateNewMovingAverageWindow(newDefaultMovingAverageWindow);
        _validateNewMaxVolatilityBps(newDefaultMaxVolatilityBps);
        _validateNewMinTimelockDuration(newDefaultMinTimelockDuration);
        _validateNewMaxTimelockDuration(newDefaultMaxTimelockDuration);
        _validateNewMaxSwappableReservoirLimitBps(newDefaultMaxSwappableReservoirLimitBps);
        _validateNewSwappableReservoirGrowthWindow(newDefaultSwappableReservoirGrowthWindow);
        defaultMovingAverageWindow = newDefaultMovingAverageWindow;
        defaultMaxVolatilityBps = newDefaultMaxVolatilityBps;
        defaultMinTimelockDuration = newDefaultMinTimelockDuration;
        defaultMaxTimelockDuration = newDefaultMaxTimelockDuration;
        defaultMaxSwappableReservoirLimitBps = newDefaultMaxSwappableReservoirLimitBps;
        defaultSwappableReservoirGrowthWindow = newDefaultSwappableReservoirGrowthWindow;
        emit DefaultParametersUpdated(
            paramSetter,
            newDefaultMovingAverageWindow,
            newDefaultMaxVolatilityBps,
            newDefaultMinTimelockDuration,
            newDefaultMaxTimelockDuration,
            newDefaultMaxSwappableReservoirLimitBps,
            newDefaultSwappableReservoirGrowthWindow
        );
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setMovingAverageWindow(address[] calldata pairs, uint32 newMovingAverageWindow) external {
        if (msg.sender != paramSetter) {
            revert Forbidden();
        }
        _validateNewMovingAverageWindow(newMovingAverageWindow);
        uint256 length = pairs.length;
        for (uint256 i; i < length; ++i) {
            IButtonswapPair(pairs[i]).setMovingAverageWindow(newMovingAverageWindow);
        }
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setMaxVolatilityBps(address[] calldata pairs, uint16 newMaxVolatilityBps) external {
        if (msg.sender != paramSetter) {
            revert Forbidden();
        }
        _validateNewMaxVolatilityBps(newMaxVolatilityBps);
        uint256 length = pairs.length;
        for (uint256 i; i < length; ++i) {
            IButtonswapPair(pairs[i]).setMaxVolatilityBps(newMaxVolatilityBps);
        }
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setMinTimelockDuration(address[] calldata pairs, uint32 newMinTimelockDuration) external {
        if (msg.sender != paramSetter) {
            revert Forbidden();
        }
        _validateNewMinTimelockDuration(newMinTimelockDuration);
        uint256 length = pairs.length;
        for (uint256 i; i < length; ++i) {
            IButtonswapPair(pairs[i]).setMinTimelockDuration(newMinTimelockDuration);
        }
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setMaxTimelockDuration(address[] calldata pairs, uint32 newMaxTimelockDuration) external {
        if (msg.sender != paramSetter) {
            revert Forbidden();
        }
        _validateNewMaxTimelockDuration(newMaxTimelockDuration);
        uint256 length = pairs.length;
        for (uint256 i; i < length; ++i) {
            IButtonswapPair(pairs[i]).setMaxTimelockDuration(newMaxTimelockDuration);
        }
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setMaxSwappableReservoirLimitBps(address[] calldata pairs, uint16 newMaxSwappableReservoirLimitBps)
        external
    {
        if (msg.sender != paramSetter) {
            revert Forbidden();
        }
        _validateNewMaxSwappableReservoirLimitBps(newMaxSwappableReservoirLimitBps);
        uint256 length = pairs.length;
        for (uint256 i; i < length; ++i) {
            IButtonswapPair(pairs[i]).setMaxSwappableReservoirLimitBps(newMaxSwappableReservoirLimitBps);
        }
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function setSwappableReservoirGrowthWindow(address[] calldata pairs, uint32 newSwappableReservoirGrowthWindow)
        external
    {
        if (msg.sender != paramSetter) {
            revert Forbidden();
        }
        _validateNewSwappableReservoirGrowthWindow(newSwappableReservoirGrowthWindow);
        uint256 length = pairs.length;
        for (uint256 i; i < length; ++i) {
            IButtonswapPair(pairs[i]).setSwappableReservoirGrowthWindow(newSwappableReservoirGrowthWindow);
        }
    }

    /**
     * @inheritdoc IButtonswapFactory
     */
    function lastCreatedTokensAndParameters()
        external
        view
        returns (
            address token0,
            address token1,
            uint32 movingAverageWindow,
            uint16 maxVolatilityBps,
            uint32 minTimelockDuration,
            uint32 maxTimelockDuration,
            uint16 maxSwappableReservoirLimitBps,
            uint32 swappableReservoirGrowthWindow
        )
    {
        token0 = lastToken0;
        token1 = lastToken1;
        movingAverageWindow = defaultMovingAverageWindow;
        maxVolatilityBps = defaultMaxVolatilityBps;
        minTimelockDuration = defaultMinTimelockDuration;
        maxTimelockDuration = defaultMaxTimelockDuration;
        maxSwappableReservoirLimitBps = defaultMaxSwappableReservoirLimitBps;
        swappableReservoirGrowthWindow = defaultSwappableReservoirGrowthWindow;
    }
}
