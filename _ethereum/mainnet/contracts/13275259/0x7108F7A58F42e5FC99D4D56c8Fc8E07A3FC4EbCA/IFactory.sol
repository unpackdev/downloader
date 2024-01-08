pragma solidity >=0.7.5;

/// @title Aastra Vault Factory
/// @author 0xKal1
/// @notice Aastra Vault Factory deploys and manages Aastra Vaults. 
/// @dev Provides an interface to the Aastra Vault Factory
interface IFactory {

    /// @notice Emitted when new vault created by factory
    /// @param strategyManager Address of strategyManager allocated to the vault
    /// @param uniswapPool Address of uniswap pool tied to the vault
    /// @param vaultAddress Address of the newly created vault
    event VaultCreation(
        address indexed strategyManager,
        address indexed uniswapPool,
        address indexed vaultAddress
    );

    /// @notice Emitted when governance of protocol gets changes
    /// @param oldGovernance Address of old governance 
    /// @param newGovernance Address of new governance 
    event GovernanceChange(
        address indexed oldGovernance,
        address indexed newGovernance
    );

    /// @notice Returns manager address of a given vault address
    /// @param _vault Address of Aastra vault
    /// @return _manager Address of vault manager
    function vaultManager(address _vault)
        external
        view
        returns (address _manager);

    /// @notice Returns vault address of a given manager address
    /// @param _manager Address of vault manager
    /// @return _vault Address of Aastra vault
    function managerVault(address _manager)
        external
        view
        returns (address _vault);

    /// @notice Creates a new Aastra vault
    /// @param _uniswapPool Address of Uniswap V3 Pool
    /// @param _strategyManager Address of strategy manager managing the vault
    /// @param _protocolFee Fee charged by strategy manager for the new vault
    /// @param _strategyFee Fee charged by protocol for the new vault
    /// @param _maxCappedLimit Max limit of TVL of the vault
    function createVault(
        address _uniswapPool,
        address _strategyManager,
        uint256 _protocolFee,
        uint256 _strategyFee,
        uint256 _maxCappedLimit
    ) external;

    /// @notice Sets a new manager for an existing vault
    /// @param _newManager Address of the new manager for the vault
    /// @param _vault Address of the Aastra vault
    function updateManager(address _newManager, address _vault) external;

    /// @notice Returns the address of Router contract
    /// @return _router Address of Router contract
    function router() external view returns (address _router);

    /// @notice Returns the address of protocol governance
    /// @return _governance Address of protocol governance
    function governance() external view returns (address _governance);


    /// @notice Returns the address of pending protocol governance
    /// @return _pendingGovernance Address of pending protocol governance
    function pendingGovernance()
        external
        view
        returns (address _pendingGovernance);

    /// @notice Allows to upgrade the router contract to a new one
    /// @param _router Address of the new router contract
    function setRouter(address _router) external;

    /// @notice Allows to set a new governance address
    /// @param _governance Address of the new protocol governance
    function setGovernance(address _governance) external;

    /// @notice Function to be called by new governance method to accept the role
    function acceptGovernance() external;
}
