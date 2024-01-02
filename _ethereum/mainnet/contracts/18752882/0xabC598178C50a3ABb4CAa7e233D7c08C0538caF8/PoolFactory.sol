// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IPool.sol";
import "./IPoolFactory.sol";
import "./IRegistry.sol";

import "./Error.sol";

import "./Clones.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./Ownable2Step.sol";
import "./SafeERC20.sol";

contract PoolFactory is Ownable2Step, IPoolFactory {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Mapping storing every authorised pool deployer for a specific token
     * following the structure account => (token => bool)
     * The boolean is set to true when the pair (account, token) is whitelisted
     * and set to false when the pair is deactivated
     */
    mapping(address => mapping(address => bool)) private deployers;

    /// @notice Set storing all the authorised pool templates
    EnumerableSet.AddressSet private templates;

    /// @notice The registry address where all the factories and pools are managed
    address public immutable registry;

    /// @notice The treasury address where the rewards are transferred to
    address public treasury;

    /// @notice The amount of protocol fee in basis points (bps) to be paid to the treasury. 1 bps is 0.01%
    uint256 public protocolFeeBps;

    /// @notice The maximum amount the protocol fee can be set to. 10,000 bps is 100%.
    uint256 public constant MAX_PCT = 10_000;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    constructor(address _owner, address _registry, address _treasury, uint256 _protocolFeeBps) Ownable(_owner) {
        if (_registry == address(0)) revert Error.ZeroAddress();
        registry = _registry;
        _setTreasury(_treasury);
        _setProtocolFee(_protocolFeeBps);
        emit PoolFactoryCreated(_owner, _registry, _treasury, _protocolFeeBps);
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolFactory
    function getTemplateAt(uint256 _index) external view returns (address) {
        return templates.at(_index);
    }

    /// @inheritdoc IPoolFactory
    function getTemplateCount() external view returns (uint256) {
        return templates.length();
    }

    /// @inheritdoc IPoolFactory
    function hasTemplate(address _template) external view returns (bool) {
        return templates.contains(_template);
    }

    /// @inheritdoc IPoolFactory
    function canDeploy(address _account, address _token) external view returns (bool) {
        return deployers[_account][_token];
    }

    /*///////////////////////////////////////////////////////////////
                            SETTERS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolFactory
    function setTreasury(address _newTreasury) external onlyOwner {
        _setTreasury(_newTreasury);
    }

    /// @inheritdoc IPoolFactory
    function setProtocolFee(uint256 _protocolFeeBps) external onlyOwner {
        _setProtocolFee(_protocolFeeBps);
    }

    /*///////////////////////////////////////////////////////////////
                        MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolFactory
    function createPool(
        address _template,
        address _token,
        uint256 _seedingPeriod,
        uint256 _lockPeriod,
        uint256 _rewardAmount,
        uint256 _maxStakePerAddress,
        uint256 _maxStakePerPool
    ) external returns (address) {
        if (!deployers[msg.sender][_token]) revert Error.Unauthorized();
        if (!templates.contains(_template)) revert Error.UnknownTemplate();

        address pool = Clones.clone(_template);

        emit PoolCreated(pool);

        // The rewards are sent to the newly created pool
        IERC20(_token).safeTransferFrom(msg.sender, pool, _rewardAmount);

        IPool(pool).initialize(
            msg.sender,
            treasury,
            _token,
            _seedingPeriod,
            _lockPeriod,
            _maxStakePerAddress,
            protocolFeeBps,
            _maxStakePerPool
        );

        IRegistry(registry).registerPool(pool);

        return pool;
    }

    /// @inheritdoc IPoolFactory
    function addTemplate(address _template) external onlyOwner {
        if (_template == address(0)) revert Error.ZeroAddress();
        if (!templates.add(_template)) revert Error.AddFailed();
        if (IPool(_template).registry() != registry) revert Error.MismatchRegistry();
        emit TemplateAdded(_template);
    }

    /// @inheritdoc IPoolFactory
    function removeTemplate(address _template) external onlyOwner {
        if (!templates.remove(_template)) revert Error.RemoveFailed();
        emit TemplateRemoved(_template);
    }

    /// @inheritdoc IPoolFactory
    function addDeployer(address _account, address _token) external onlyOwner {
        if (_account == address(0)) revert Error.ZeroAddress();
        if (_token == address(0)) revert Error.ZeroAddress();
        deployers[_account][_token] = true;
        emit DeployerAdded(_account, _token);
    }

    /// @inheritdoc IPoolFactory
    function removeDeployer(address _account, address _token) external onlyOwner {
        if (!deployers[_account][_token]) revert Error.DeployerNotFound();
        deployers[_account][_token] = false;
        emit DeployerRemoved(_account, _token);
    }

    /*///////////////////////////////////////////////////////////////
    								INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifies the treasury address
     * @param _newTreasury The new treasury address
     */
    function _setTreasury(address _newTreasury) internal {
        if (_newTreasury == address(0)) revert Error.ZeroAddress();
        emit TreasurySet(treasury, _newTreasury);
        treasury = _newTreasury;
    }

    /**
     * @notice Modifies the protocol fee
     * @param _protocolFeeBps The new protocol fee amount
     */
    function _setProtocolFee(uint256 _protocolFeeBps) internal {
        if (_protocolFeeBps > MAX_PCT) revert Error.FeeTooHigh();
        emit ProtocolFeeSet(protocolFeeBps, _protocolFeeBps);
        protocolFeeBps = _protocolFeeBps;
    }
}
