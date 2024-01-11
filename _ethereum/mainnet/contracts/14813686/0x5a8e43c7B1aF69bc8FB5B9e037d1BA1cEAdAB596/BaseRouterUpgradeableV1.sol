// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./SafeERC20Upgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IBaseRouterUpgradeable.sol";
import "./IAccessControlUpgradeable.sol";

import "./VaultAPI.sol";

interface RegistryAPI {
    function governance() external view returns (address);

    function latestVault(address token) external view returns (address);

    function numVaults(address token) external view returns (uint256);

    function vaults(address token, uint256 deploymentId)
        external
        view
        returns (address);
}

/**
 * @notice
 *  Based on BaseRouter Yearn Finance Smart Contract
 *
 */
contract BaseRouterUpgradeableV1 is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IBaseRouterUpgradeable
{
    bytes32 public constant CONTRACT_UPDATER = keccak256("CONTRACT_UPDATER");
    event RolesSet(address indexed oldRoles, address indexed newRoles);
    event RegistrySet(address indexed oldRegistry, address indexed newRegistry);
    IAccessControlUpgradeable public roles;

    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // Reduce number of external calls (SLOADs stay the same)
    mapping(address => VaultAPI[]) private _cachedVaults;

    RegistryAPI public registry;

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function initialize(address _registry, address _roles) public initializer {
        // Recommended to use `v2.registry.ychad.eth`
        registry = RegistryAPI(_registry);
        _setRoleContract(_roles);
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _setRoleContract(address _roles) private {
        _validateAddress(_roles);
        address oldRoles = address(roles);
        roles = IAccessControlUpgradeable(_roles);
        emit RolesSet(oldRoles, address(roles));
    }

    function _validateAddress(address _addr) private view {
        require(_addr != address(0) && _addr != address(this), "IA");
    }

    function _verifyContractUpdaterRole() private view {
        require(roles.hasRole(CONTRACT_UPDATER, msg.sender), "UCUA");
    }

    /**
     * @notice
     *  Used to update the yearn registry.
     * @param _registry The new _registry address.
     */
    function setRegistry(address _registry) external override {
        _validateAddress(_registry);
        _verifyContractUpdaterRole();
        address oldRegistry = address(registry);
        registry = RegistryAPI(_registry);
        emit RegistrySet(oldRegistry, _registry);
    }

    /**
     * @notice
     *  Used to get the most revent vault for the token using the registry.
     * @return An instance of a VaultAPI
     */
    function bestVault(address token)
        public
        view
        virtual
        override
        returns (VaultAPI)
    {
        return VaultAPI(registry.latestVault(token));
    }

    /**
     * @notice
     *  Used to get all vaults from the registery for the token
     * @return An array containing instances of VaultAPI
     */
    function allVaults(address token)
        public
        view
        virtual
        override
        returns (VaultAPI[] memory)
    {
        uint256 cache_length = _cachedVaults[token].length;
        uint256 num_vaults = registry.numVaults(token);

        // Use cached
        if (cache_length == num_vaults) {
            return _cachedVaults[token];
        }

        VaultAPI[] memory vaults = new VaultAPI[](num_vaults);

        for (uint256 vault_id = 0; vault_id < cache_length; vault_id++) {
            vaults[vault_id] = _cachedVaults[token][vault_id];
        }

        for (
            uint256 vault_id = cache_length;
            vault_id < num_vaults;
            vault_id++
        ) {
            vaults[vault_id] = VaultAPI(registry.vaults(token, vault_id));
        }

        return vaults;
    }

    function updateVaultCache(address token)
        public
        override
        returns (VaultAPI[] memory vaults)
    {
        verifyVaultExist(token); //proceed only if the vault exists
        vaults = allVaults(token);
        _updateVaultCache(token, vaults);
    }

    function _updateVaultCache(address token, VaultAPI[] memory vaults)
        internal
    {
        // NOTE: even though `registry` is update-able by Yearn, the intended behavior
        //       is that any future upgrades to the registry will replay the version
        //       history so that this cached value does not get out of date.
        if (vaults.length > _cachedVaults[token].length) {
            _cachedVaults[token] = vaults;
        }
    }

    /**
     * @notice
     *  Used to get the balance of an account accross all the vaults for a token.
     *  @dev will be used to get the router balance using totalVaultBalance(address(this)).
     *  @param account The address of the account.
     *  @return balance of token for the account accross all the vaults.
     */
    function totalVaultBalance(address token, address account)
        public
        view
        override
        returns (uint256 balance)
    {
        VaultAPI[] memory vaults = allVaults(token);

        for (uint256 id = 0; id < vaults.length; id++) {
            balance = balance.add(
                vaults[id]
                    .balanceOf(account)
                    .mul(vaults[id].pricePerShare())
                    .div(10**uint256(vaults[id].decimals()))
            );
        }
    }

    /**
     * @notice
     *  Used to get the TVL on the underlying vaults.
     *  @return assets the sum of all the assets managed by the underlying vaults.
     */
    function totalAssets(address token)
        public
        view
        override
        returns (uint256 assets)
    {
        VaultAPI[] memory vaults = allVaults(token);

        for (uint256 id = 0; id < vaults.length; id++) {
            assets = assets.add(vaults[id].totalAssets());
        }
    }

    function verifyVaultExist(address token) public view override {
        require(registry.latestVault(token) != address(0), "TANR");
    }
}
