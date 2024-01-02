// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./Initializable.sol";
import "./ClonesUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IICHIVault.sol";
import "./IRebalancerFactory.sol";
import "./IRebalancerCommon.sol";

contract RebalancerFactory is IRebalancerFactory, Initializable, AccessControlUpgradeable {
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    address private constant NULL_ADDRESS = address(0);

    // Define Roles
    bytes32 public constant STRATEGY_TYPE_REGISTRAR_ROLE = keccak256("STRATEGY_TYPE_REGISTRAR_ROLE");
    bytes32 public constant STRATEGY_DEPLOYER_ROLE = keccak256("STRATEGY_DEPLOYER_ROLE");
    bytes32 public constant LEGACY_STRATEGY_REGISTRAR_ROLE = keccak256("LEGACY_STRATEGY_REGISTRAR_ROLE");
    bytes32 public constant STRATEGY_TYPE_ACTIVE_SETTER_ROLE = keccak256("STRATEGY_TYPE_ACTIVE_SETTER_ROLE");
    bytes32 public constant STRATEGY_ENABLE_SETTER_ROLE = keccak256("STRATEGY_ENABLE_SETTER_ROLE");
 
    // Store strategy types and instances
    StrategyType[] strategyTypes;

    // Store vaults and instances
    EnumerableSetUpgradeable.AddressSet vaultSet;
    mapping(address => Vault) private vaults;

    // Store strategy instances
    EnumerableSetUpgradeable.AddressSet strategyInstanceSet;
    mapping(address => StrategyInstance) private strategyInstances;

    function initialize() external virtual initializer {        
        // Initialize AccessControlUpgradeable
        __AccessControl_init();

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(STRATEGY_TYPE_REGISTRAR_ROLE, _msgSender());
        _setupRole(STRATEGY_DEPLOYER_ROLE, _msgSender());
        _setupRole(LEGACY_STRATEGY_REGISTRAR_ROLE, _msgSender());
        _setupRole(STRATEGY_TYPE_ACTIVE_SETTER_ROLE, _msgSender());
        _setupRole(STRATEGY_ENABLE_SETTER_ROLE, _msgSender());

        // Emit RebalancerFactoryInitialized event
        emit RebalancerFactoryInitialized();
    }

    function registerStrategyType(
        address implementation,
        string calldata description,
        bool deployable
    ) external virtual override onlyRole(STRATEGY_TYPE_REGISTRAR_ROLE) {
        require(!deployable || implementation != NULL_ADDRESS, "RF:registerStrategyType:implementation cannot be null");
        require(bytes(description).length > 0, "RF:registerStrategyType:description cannot empty");
        uint256 typeId = strategyTypes.length;

        strategyTypes.push();
        StrategyType storage newStrategyType = strategyTypes[typeId];

        newStrategyType.implementation = implementation;
        newStrategyType.description = description;
        newStrategyType.deployable = deployable;

        emit StrategyTypeRegistered(
            typeId,
            implementation,
            deployable,
            description
        );
    }

    function deployStrategyInstance(
        uint256 typeId,
        address owner,
        address vault,
        address vaultFactory,
        bytes calldata initData
    ) external virtual override onlyRole(STRATEGY_DEPLOYER_ROLE) returns (address strategyInstance) {
        require(isStrategyType(typeId), "RF:deployStrategyInstance:Invalid typeId");
        require(owner != NULL_ADDRESS, "RF:deployStrategyInstance:owner cannot be null");
        require(vault != NULL_ADDRESS, "RF:deployStrategyInstance:vault cannot be null");
        require(vaultFactory != NULL_ADDRESS, "RF:deployStrategyInstance:vaultFactory cannot be null");
        require(IICHIVault(vault).ichiVaultFactory() == vaultFactory, "RF:deployStrategyInstance:vault and factory must match");
        StrategyType storage strategyType = strategyTypes[typeId];
        require(strategyType.deployable, "RF:deployStrategyInstance:Strategy type not deployable");

        // Deploy and initialize the strategy
        strategyInstance = ClonesUpgradeable.clone(strategyType.implementation);
        IRebalancerCommon(strategyInstance).initialize(vault, owner, initData);

        _registerVaultStrategy(
            typeId,
            strategyInstance,
            vault
        );

        emit StrategyInstanceDeployed(typeId, strategyInstance, owner, vault, initData);
    }

    function _registerVaultStrategy(
        uint256 typeId, 
        address strategyInstance, 
        address vault      
    ) internal virtual {
        StrategyType storage strategyType = strategyTypes[typeId];

        // Add vault instance to vault set
        if (!vaultSet.contains(vault)) {
            vaultSet.add(vault);
        }

        // Add strategy instance to strategy instance set
        strategyInstanceSet.add(strategyInstance);
        strategyInstances[strategyInstance].typeId = typeId;
        strategyInstances[strategyInstance].strategy = strategyInstance;
        strategyInstances[strategyInstance].vault = vault;
        strategyInstances[strategyInstance].enabled = true;

        // Add strategy instance to type strategy instance set
        strategyType.strategySet.add(strategyInstance);

        // Add strategy instance to vault strategy instance set
        vaults[vault].strategyInstanceSet.add(strategyInstance);        
    }

    function registerLegacyStrategy(
        uint256 typeId, 
        address strategyInstance, 
        address vault,
        address vaultFactory
    ) external virtual override onlyRole(LEGACY_STRATEGY_REGISTRAR_ROLE) {
        require(isStrategyType(typeId), "RF:registerLegacyStrategy:Invalid typeId");
        require(strategyInstance != NULL_ADDRESS, "RF:registerLegacyStrategy:strategy instance cannot be null");
        require(vault != NULL_ADDRESS, "RF:registerLegacyStrategy:vault canot be null");
        require(vaultFactory != NULL_ADDRESS, "RF:registerLegacyStrategy:vaultFactory cannot be null");
        require(IICHIVault(vault).ichiVaultFactory() == vaultFactory, "RF:registerLegacyStrategy:vault and factory must match");

        _registerVaultStrategy(
            typeId,
            strategyInstance,
            vault
        );

        // Emit event
        emit LegacyStrategyRegistered(typeId, strategyInstance, vault);
    }

    function enableStrategyType(uint256 typeId) external virtual override onlyRole(STRATEGY_TYPE_ACTIVE_SETTER_ROLE) {
        require(isStrategyType(typeId), "RF:enableStrategyType:Invalid typeId");
        require(strategyTypes[typeId].implementation != NULL_ADDRESS, "RF:enableStrategyType:implementation cannot be null");
        strategyTypes[typeId].deployable = true;
        emit StrategyTypeEnabled(typeId);
    }

    function disableStrategyType(uint256 typeId) external virtual override onlyRole(STRATEGY_TYPE_ACTIVE_SETTER_ROLE) {
        require(isStrategyType(typeId), "RF:disableStrategyType:Invalid typeId");
        strategyTypes[typeId].deployable = false;
        emit StrategyTypeDisabled(typeId);
    }

    function markStrategyEnabled(address strategyAddress) external virtual override onlyRole(STRATEGY_ENABLE_SETTER_ROLE) {
        require(strategyInstanceSet.contains(strategyAddress),"RF:markStrategyEnabled:Strategy not found");
        strategyInstances[strategyAddress].enabled = true;
        emit StrategyEnabled(strategyAddress);
    }

    function markStrategyDisabled(address strategyAddress) external virtual override onlyRole(STRATEGY_ENABLE_SETTER_ROLE) {
        require(strategyInstanceSet.contains(strategyAddress),"RF:markStrategyDisabled:Strategy not found");
        strategyInstances[strategyAddress].enabled = false;
        emit StrategyDisabled(strategyAddress);
    }

    function isStrategyEnabled(address strategyAddress) external virtual view override returns (bool isEnabled) {
        require(strategyInstanceSet.contains(strategyAddress),"RF:isStrategyEnabled:strategy not found");
        isEnabled = strategyInstances[strategyAddress].enabled;
    }

    function getStrategyTypeCount() external view virtual override returns (uint256 count) {
        count = strategyTypes.length;
    }

    function getTypeStrategyByIndex(
        uint256 typeId, 
        uint256 index
    ) external view virtual override returns (StrategyInstance memory strategyInstance) {
        require (isStrategyType(typeId), "RF:getTypeStrategyByIndex:typeId not found");
        StrategyType storage t = strategyTypes[typeId];
        require (index < t.strategySet.length(), "RF:getTypeStrategyByIndex:index out of range");
        strategyInstance = strategyInstances[t.strategySet.at(index)];
    }

    function getStrategyType(
        address strategy
    ) external view virtual override returns (
        string memory description, 
        bool active, 
        address implementation,
        uint256 strategyCount) 
    {
        require(isStrategyInstance(strategy),"RF:getStrategyType:Strategy not found");
        return getStrategyTypeById(strategyInstances[strategy].typeId);
    }

    function getStrategyTypeById(uint256 typeId) public view virtual override returns (
        string memory description,
        bool active,
        address implementation,
        uint256 strategyCount
    )
    {
        require(isStrategyType(typeId), "RF:getStrategyTypeById:typeId not found");
        StrategyType storage strategyType = strategyTypes[typeId];
        description = strategyType.description;
        active = strategyType.deployable;
        implementation = strategyType.implementation;
        strategyCount = strategyType.strategySet.length();
    }

    function getTypeStrategyCount(uint256 typeId) external view virtual override returns (uint256 count) {
        require(isStrategyType(typeId), "RF:getTypeStrategyCount:Invalid typeId");
        count = strategyTypes[typeId].strategySet.length();
    }

    function getTypeStrategies(
        uint256 typeId
    ) external view virtual override returns (
        StrategyInstance[] memory typeStrategyInstances) 
    {
        require(isStrategyType(typeId), "RF:getTypeStrategies:Invalid typeId");

        typeStrategyInstances = new StrategyInstance[](strategyTypes[typeId].strategySet.length());

        for (uint256 i = 0; i < typeStrategyInstances.length; i++) {
            address strategyInstance = strategyTypes[typeId].strategySet.at(i);
            typeStrategyInstances[i] = strategyInstances[strategyInstance];
        }
    }

    function isStrategyType(uint256 typeId) public view virtual override returns (bool isIndeed) {
        isIndeed = typeId < strategyTypes.length;
    }

    function getStrategyInstanceCount() external view virtual override returns (uint256 count) {
        count = strategyInstanceSet.length();
    }

    function getStrategyInstance(
        address strategyAddress
    ) public view virtual override returns (
        StrategyInstance memory strategyInstance) 
    {
        require(isStrategyInstance(strategyAddress), "RF:getStrategyInstance:strategy not found");
        strategyInstance = strategyInstances[strategyAddress];
    }

    function isStrategyInstance(address strategyAddress) public view virtual override returns (bool isIndeed) {
        isIndeed = strategyInstanceSet.contains(strategyAddress);
    }

    function getVaultStrategyCount(address vaultAddress) external view virtual override returns (uint256 count) {
        require(vaultSet.contains(vaultAddress),"RF:getVaultStrategyCount:vault not found");
        count = vaults[vaultAddress].strategyInstanceSet.length();
    }

    function getVaultStrategyByIndex(
        address vaultAddress, 
        uint256 index
    ) external view virtual override returns (
        StrategyInstance memory strategyInstance) 
    {
        require(vaultSet.contains(vaultAddress),"RF:getVaultStrategyByIndex:vault not found");
        require(index < vaults[vaultAddress].strategyInstanceSet.length(),"RF:getVaultStrategyByIndex:index out of range");
        address strategy = vaults[vaultAddress].strategyInstanceSet.at(index);
        strategyInstance = getStrategyInstance(strategy);
    }

    function getVaultStrategies(
        address vaultAddress
    ) external view virtual override returns (
        StrategyInstance[] memory vaultStrategyInstances) 
    {
        require(vaultSet.contains(vaultAddress),"RF:getVaultStrategies:vault not found");
        uint256 strategyCount = vaults[vaultAddress].strategyInstanceSet.length();
        vaultStrategyInstances = new StrategyInstance[](strategyCount);

        for (uint256 i = 0; i < strategyCount; i++) {
            address strategyInstance = vaults[vaultAddress].strategyInstanceSet.at(i);
            vaultStrategyInstances[i] = strategyInstances[strategyInstance];
        }
    }

    function isVaultStrategy(
        address vaultAddress, 
        address strategyAddress
    ) external view virtual override returns (bool isIndeed) {
        require(vaultSet.contains(vaultAddress),"RF:isVaultStrategy:vault not found");
        isIndeed = vaults[vaultAddress].strategyInstanceSet.contains(strategyAddress);
    }

    function getVaultCount() external view virtual override returns (uint256 count) {
        count = vaultSet.length();
    }

    function getVaultByIndex(uint256 index) external view virtual override returns (address vault) {
        require(index < vaultSet.length(),"RF:getVaultByIndex:index out of range");
        vault = vaultSet.at(index);
    }

}