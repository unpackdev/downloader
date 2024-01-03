// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./SafeERC20Upgradeable.sol";
import "./IUniswapV2Router02.sol";
import "./Initializable.sol";
import "./IStrategyHelper.sol";
import "./IUniswapV2Pair.sol";
import "./ISwapRouter.sol";
import "./BytesLib.sol";
import "./StrategyHelperErrors.sol";
import "./IAdminStructure.sol";
import "./IBalancer.sol";
import "./AddressUtils.sol";
import "./ICurve.sol";
import "./ERC20Lib.sol";
import "./IOracle.sol";
import "./IERC20.sol";
import "./IWETH.sol";

/**
 * @title Dollet StrategyHelper
 * @author Dollet Team
 * @notice A StrategyHelper contract. It includes helper methods to price assets, value assets, convert one asset to
 *         another, swap two assets, etc.
 */
contract StrategyHelper is Initializable, IStrategyHelper {
    using SafeERC20Upgradeable for IERC20;
    using AddressUtils for address;

    uint16 public constant ONE_HUNDRED_PERCENTS = 10_000; // 100.00%
    uint16 public constant MAX_SLIPPAGE_TOLERANCE = 3000; // 30.00%

    mapping(address asset => address oracle) public oracles;
    mapping(address from => mapping(address to => Path path)) public paths;
    IAdminStructure public adminStructure;

    /**
     * @notice Checks if a transaction sender is a super admin.
     */
    modifier onlyAdmin() {
        adminStructure.isValidAdmin(msg.sender);
        _;
    }

    /**
     * @notice Checks if a transaction sender is a super admin.
     */
    modifier onlySuperAdmin() {
        adminStructure.isValidSuperAdmin(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes this StrategyHelper contract.
     * @param _adminStructure AdminStructure contract address.
     */
    function initialize(address _adminStructure) external initializer {
        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /// @inheritdoc IStrategyHelper
    function setAdminStructure(address _adminStructure) external onlySuperAdmin {
        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /// @inheritdoc IStrategyHelper
    function setOracle(address _asset, address _oracle) external onlyAdmin {
        AddressUtils.onlyContract(_asset);
        AddressUtils.onlyContract(_oracle);

        oracles[_asset] = _oracle;

        emit OracleSet(_asset, _oracle);
    }

    /// @inheritdoc IStrategyHelper
    function setPath(address _from, address _to, address _venue, bytes calldata _path) external onlyAdmin {
        AddressUtils.onlyContract(_from);
        AddressUtils.onlyContract(_to);
        AddressUtils.onlyContract(_venue);

        Path memory _newPath = Path({ venue: _venue, path: _path });

        paths[_from][_to] = _newPath;

        emit PathSet(_from, _to, _venue, _path);
    }

    /// @inheritdoc IStrategyHelper
    function swap(
        address _from,
        address _to,
        uint256 _amount,
        uint16 _slippageTolerance,
        address _recipient
    )
        external
        returns (uint256)
    {
        AddressUtils.onlyContract(_from);
        AddressUtils.onlyContract(_to);

        if (_recipient == address(0)) revert StrategyHelperErrors.WrongRecipient();
        if (_amount == 0) return 0;

        if (_from == _to) {
            IERC20(_from).safeTransferFrom(msg.sender, _recipient, _amount);

            return _amount;
        }

        Path memory _path = paths[_from][_to];

        if (_path.venue == address(0)) revert StrategyHelperErrors.UnknownPath();

        IERC20(_from).safeTransferFrom(msg.sender, _path.venue, _amount);

        if (_slippageTolerance > MAX_SLIPPAGE_TOLERANCE) revert StrategyHelperErrors.WrongSlippageTolerance();

        uint256 _minAmountOut =
            (convert(_from, _to, _amount) * (ONE_HUNDRED_PERCENTS - _slippageTolerance)) / ONE_HUNDRED_PERCENTS;

        if (_minAmountOut == 0) revert StrategyHelperErrors.ZeroMinimumOutputAmount();

        uint256 _beforeBalance = IERC20(_to).balanceOf(_recipient);

        IStrategyHelperVenue(_path.venue).swap(_from, _path.path, _amount, _minAmountOut, _recipient, block.timestamp);

        return IERC20(_to).balanceOf(_recipient) - _beforeBalance;
    }

    /// @inheritdoc IStrategyHelper
    function price(address _asset) public view returns (uint256) {
        IOracle _oracle = IOracle(oracles[_asset]);

        if (address(_oracle) == address(0)) revert StrategyHelperErrors.UnknownOracle();

        return (uint256(_oracle.latestAnswer()) * 1e18) / (10 ** _oracle.decimals());
    }

    /// @inheritdoc IStrategyHelper
    function value(address _asset, uint256 _amount) public view returns (uint256) {
        return (_amount * price(_asset)) / (10 ** IERC20(_asset).decimals());
    }

    /// @inheritdoc IStrategyHelper
    function convert(address _from, address _to, uint256 _amount) public view returns (uint256) {
        return (value(_from, _amount) * (10 ** IERC20(_to).decimals())) / price(_to);
    }
}

/**
 * @title Dollet StrategyHelperVenueUniswapV2
 * @author Dollet Team
 * @notice StrategyHelperVenue that executes swaps on the Uniswap V2 venue.
 */
contract StrategyHelperVenueUniswapV2 is IStrategyHelperVenue {
    using AddressUtils for address;

    IUniswapV2Router02 public immutable router;

    /**
     * @notice Initializes this StrategyHelperVenueUniswapV2 contract.
     * @param _router A Uniswap V2 router address.
     */
    constructor(address _router) {
        AddressUtils.onlyContract(_router);

        router = IUniswapV2Router02(_router);
    }

    /// @inheritdoc IStrategyHelperVenue
    function swap(
        address _asset,
        bytes calldata _path,
        uint256 _amount,
        uint256 _minAmountOut,
        address _recipient,
        uint256 _deadline
    )
        external
    {
        IUniswapV2Router02 _router = router;

        ERC20Lib.safeApprove(_asset, address(_router), _amount);
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount, _minAmountOut, _parsePath(_path), _recipient, _deadline
        );
    }

    /**
     * @notice Parses encoded Uniswap V2 swap path.
     * @param _path A swap path to decode.
     * @return _tokens A list of token addresses to use during the swap.
     */
    function _parsePath(bytes memory _path) private pure returns (address[] memory _tokens) {
        uint256 _size = _path.length / 20;

        _tokens = new address[](_size);

        for (uint256 _i; _i < _size;) {
            _tokens[_i] = address(uint160(bytes20(BytesLib.slice(_path, _i * 20, 20))));

            unchecked {
                ++_i;
            }
        }
    }
}

/**
 * @title Dollet StrategyHelperVenueUniswapV3
 * @author Dollet Team
 * @notice StrategyHelperVenue that executes swaps on the Uniswap V3 venue.
 */
contract StrategyHelperVenueUniswapV3 is IStrategyHelperVenue {
    using AddressUtils for address;

    ISwapRouter public immutable router;

    /**
     * @notice Initializes this StrategyHelperVenueUniswapV3 contract.
     * @param _router A Uniswap V3 router address.
     */
    constructor(address _router) {
        AddressUtils.onlyContract(_router);

        router = ISwapRouter(_router);
    }

    /// @inheritdoc IStrategyHelperVenue
    function swap(
        address _asset,
        bytes calldata _path,
        uint256 _amount,
        uint256 _minAmountOut,
        address _recipient,
        uint256 _deadline
    )
        external
    {
        ISwapRouter _router = router;

        ERC20Lib.safeApprove(_asset, address(_router), _amount);
        _router.exactInput(
            ISwapRouter.ExactInputParams({
                path: _path,
                recipient: _recipient,
                deadline: _deadline,
                amountIn: _amount,
                amountOutMinimum: _minAmountOut
            })
        );
    }
}

/**
 * @title Dollet StrategyHelperVenueCurve
 * @author Dollet Team
 * @notice StrategyHelperVenue that executes swaps on the Curve venue.
 */
contract StrategyHelperVenueCurve is IStrategyHelperVenue {
    using SafeERC20Upgradeable for IERC20;
    using AddressUtils for address;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IWETH public immutable weth;

    /**
     * @notice Initializes this StrategyHelperVenueCurve contract.
     * @param _weth A WETH token contract address.
     */
    constructor(address _weth) {
        AddressUtils.onlyContract(_weth);

        weth = IWETH(_weth);
    }

    /**
     * @notice Allows this contract to receive native token (ETH).
     */
    receive() external payable { }

    /// @inheritdoc IStrategyHelperVenue
    function swap(
        address _asset,
        bytes calldata _path,
        uint256 _amount,
        uint256 _minAmountOut,
        address _recipient,
        uint256 _deadline
    )
        external
    {
        if (_deadline < block.timestamp) revert StrategyHelperErrors.ExpiredDeadline();

        (address[] memory _pools, uint256[] memory _coinsIn, uint256[] memory _coinsOut) =
            abi.decode(_path, (address[], uint256[], uint256[]));
        uint256 _poolsLength = _pools.length;
        address _lastToken = _asset;
        uint256 _lastAmount = _amount;
        IWETH _weth = weth;

        for (uint256 _i; _i < _poolsLength;) {
            ICurvePool _pool = ICurvePool(_pools[_i]);
            uint256 _coinIn = _coinsIn[_i];
            uint256 _coinOut = _coinsOut[_i];
            uint256 _value;
            address _tokenIn = _pool.coins(_coinIn);

            if (_tokenIn == ETH && _lastToken == address(_weth)) {
                _weth.withdraw(_lastAmount);
                _value = _lastAmount;
            } else {
                ERC20Lib.safeApprove(_tokenIn, address(_pool), _lastAmount);
            }

            try _pool.exchange{ value: _value }(_coinIn, _coinOut, _lastAmount, 0) { }
            catch {
                _pool.exchange{ value: _value }(int128(uint128(_coinIn)), int128(uint128(_coinOut)), _lastAmount, 0);
            }

            _lastToken = _pool.coins(_coinOut);

            if (_lastToken == ETH) {
                _lastToken = address(_weth);
                _weth.deposit{ value: address(this).balance }();
            }

            _lastAmount = IERC20(_lastToken).balanceOf(address(this));

            unchecked {
                ++_i;
            }
        }

        if (_lastAmount < _minAmountOut) revert StrategyHelperErrors.UnderMinimumOutputAmount();

        IERC20(_lastToken).safeTransfer(_recipient, _lastAmount);
    }
}

/**
 * @title Dollet StrategyHelperVenueBalancer
 * @author Dollet Team
 * @notice StrategyHelperVenue that executes swaps on the Balancer venue.
 */
contract StrategyHelperVenueBalancer is IStrategyHelperVenue {
    using AddressUtils for address;

    IBalancerVault public immutable vault;

    /**
     * @notice Initializes this StrategyHelperVenueBalancer contract.
     * @param _vault A Balancer Vault contract address.
     */
    constructor(address _vault) {
        AddressUtils.onlyContract(_vault);

        vault = IBalancerVault(_vault);
    }

    /// @inheritdoc IStrategyHelperVenue
    function swap(
        address _asset,
        bytes calldata _path,
        uint256 _amount,
        uint256 _minAmountOut,
        address _recipient,
        uint256 _deadline
    )
        external
    {
        IBalancerVault _vault = vault;
        (address _assetOut, bytes32 _poolId) = abi.decode(_path, (address, bytes32));

        ERC20Lib.safeApprove(_asset, address(_vault), _amount);
        _vault.swap(
            IBalancerVault.SingleSwap({
                poolId: _poolId,
                kind: 0,
                assetIn: _asset,
                assetOut: _assetOut,
                amount: _amount,
                userData: ""
            }),
            IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(_recipient),
                toInternalBalance: false
            }),
            _minAmountOut,
            _deadline
        );
    }
}
