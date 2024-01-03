// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./Initializable.sol";
import "./IStrategyHelper.sol";
import "./IAdminStructure.sol";
import "./OracleErrors.sol";
import "./AddressUtils.sol";
import "./ICurve.sol";
import "./IOracle.sol";
import "./IERC20.sol";

/**
 * @title Dollet OracleCurve contract
 * @author Dollet Team
 * @notice An oracle for a token that uses a Curve pool to price it. Can be used only for pools with 2 tokens.
 */
contract OracleCurve is Initializable, IOracle {
    using AddressUtils for address;

    IAdminStructure public adminStructure;
    IStrategyHelper public strategyHelper;
    ICurvePool public pool;
    uint256 public index;
    address public tokenA;
    address public tokenB;
    address public weth;

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
     * @notice Initializes this contract in time of deployment.
     * @param _adminStructure AdminStructure contract address.
     * @param _strategyHelper StrategyHelper contract address.
     * @param _pool Address of the Curve pool.
     * @param _index Index of the token in the Curve pool.
     * @param _weth WETH token address.
     */
    function initialize(
        address _adminStructure,
        address _strategyHelper,
        address _pool,
        uint256 _index,
        address _weth
    )
        external
        initializer
    {
        AddressUtils.onlyContract(_adminStructure);
        AddressUtils.onlyContract(_strategyHelper);
        AddressUtils.onlyContract(_pool);
        AddressUtils.onlyContract(_weth);

        if (_index > 1) revert OracleErrors.WrongCurvePoolTokenIndex();

        adminStructure = IAdminStructure(_adminStructure);
        strategyHelper = IStrategyHelper(_strategyHelper);
        pool = ICurvePool(_pool);
        index = _index;
        weth = _weth;
        tokenA = _parseToken(ICurvePool(_pool).coins(_index));
        tokenB = _parseToken(ICurvePool(_pool).coins((_index + 1) % 2));
    }

    /// @inheritdoc IOracle
    function setAdminStructure(address _adminStructure) external onlySuperAdmin {
        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /// @inheritdoc IOracle
    function latestAnswer() external view returns (int256) {
        return _latestAnswer();
    }

    /// @inheritdoc IOracle
    function latestRoundData()
        external
        view
        returns (uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound)
    {
        return (0, _latestAnswer(), block.timestamp, block.timestamp, 0);
    }

    /// @inheritdoc IOracle
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @notice Parse the token address and handle native token.
     * @param _token Address of the token to parse.
     * @return The parsed token address.
     */
    function _parseToken(address _token) private view returns (address) {
        if (_token == address(0) || _token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) return weth;

        return _token;
    }

    /**
     * @notice Returns the latest answer.
     * @return The latest answer.
     */
    function _latestAnswer() private view returns (int256) {
        int128 _i = int128(int256(index));
        // Price one unit of token (that we are pricing) converted to token (that it's paired with)
        uint256 _amount = pool.get_dy(_i, (_i + 1) % 2, 10 ** IERC20(tokenA).decimals());

        // Value the token it's paired with using it's oracle
        return int256(strategyHelper.value(address(tokenB), _amount));
    }
}
