// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "./Initializable.sol";
import "./IBalancer.sol";
import "./IAdminStructure.sol";
import "./OracleErrors.sol";
import "./AddressUtils.sol";
import "./IOracle.sol";
import "./IERC20.sol";

/**
 * @title Dollet OracleBalancerWeighted
 * @author Dollet Team
 * @notice An oracle for a token that uses Balancer weighted pool to price it. Only pools with 2 tokens are supported by
 *         this oracle. One of them must be WETH.
 */
contract OracleBalancerWeighted is Initializable, IOracle {
    using AddressUtils for address;

    uint32 public constant MAX_VALIDITY_DURATION = 2 days;

    IAdminStructure public adminStructure;
    IBalancerVault public vault;
    IBalancerPool public pool;
    IOracle public ethOracle;
    uint256 public tokenIndex;
    uint256 public wethIndex;
    uint32 public validityDuration;

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
     * @param _adminStructure Admin structure contract address.
     * @param _vault Balancer Vault contract address.
     * @param _pool Balancer Pool contract address.
     * @param _ethOracle ETH oracle contract address.
     * @param _validityDuration A duration (in seconds) during which the latest answer from the oracle is valid.
     */
    function initialize(
        address _adminStructure,
        address _vault,
        address _pool,
        address _ethOracle,
        address _weth,
        uint32 _validityDuration
    )
        external
        initializer
    {
        AddressUtils.onlyContract(_adminStructure);
        AddressUtils.onlyContract(_vault);
        AddressUtils.onlyContract(_pool);
        AddressUtils.onlyContract(_ethOracle);
        AddressUtils.onlyContract(_weth);

        adminStructure = IAdminStructure(_adminStructure);
        vault = IBalancerVault(_vault);
        pool = IBalancerPool(_pool);
        ethOracle = IOracle(_ethOracle);

        _setValidityDuration(_validityDuration);

        (IERC20[] memory _tokens,,) = IBalancerVault(_vault).getPoolTokens(IBalancerPool(_pool).getPoolId());

        if (_tokens.length > 2) revert OracleErrors.WrongBalancerPoolTokensNumber();

        address(_tokens[0]) == _weth ? tokenIndex = 1 : wethIndex = 1;
    }

    /// @inheritdoc IOracle
    function setAdminStructure(address _adminStructure) external onlySuperAdmin {
        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /**
     * @notice Sets a new validity duration (in seconds) by an owner.
     * @param _newValidityDuration A new duration (in seconds) during which the latest answer from the oracle is valid.
     */
    function setValidityDuration(uint32 _newValidityDuration) external onlySuperAdmin {
        _setValidityDuration(_newValidityDuration);
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
     * @notice Sets a new validity duration (in seconds).
     * @param _newValidityDuration A new duration (in seconds) during which the latest answer from the oracle is valid.
     */
    function _setValidityDuration(uint32 _newValidityDuration) private {
        if (_newValidityDuration == 0 || _newValidityDuration > MAX_VALIDITY_DURATION) {
            revert OracleErrors.WrongValidityDuration();
        }

        validityDuration = _newValidityDuration;
    }

    /**
     * @notice Returns the latest answer.
     * @return The latest answer.
     */
    function _latestAnswer() private view returns (int256) {
        IOracle _ethOracle = ethOracle;
        (, int256 _answer,, uint256 _updatedAt,) = _ethOracle.latestRoundData();

        if (block.timestamp - _updatedAt > validityDuration) revert OracleErrors.StalePrice();

        uint256 _ethPrice = (uint256(_answer) * 1e18) / 10 ** _ethOracle.decimals();
        IBalancerPool _pool = pool;
        (, uint256[] memory _balances,) = vault.getPoolTokens(_pool.getPoolId());
        uint256[] memory _weights = _pool.getNormalizedWeights();
        uint256 _tokenIndex = tokenIndex;
        uint256 _wethIndex = wethIndex;
        uint256 _tokenPrice = (((_balances[_tokenIndex] * 1e18) / _weights[_tokenIndex]) * 1e18)
            / ((_balances[_wethIndex] * 1e18) / _weights[_wethIndex]);

        return int256((_ethPrice * 1e18) / _tokenPrice);
    }
}
