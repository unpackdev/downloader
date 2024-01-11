// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "OwnableUpgradeable.sol";
import "UUPSUpgradeable.sol";
import "IVault.sol";

interface IReleaseRegistry {
    function numReleases() external view returns (uint256);

    function releases(uint256 _version) external view returns (address);

    function newVault(
        address _token,
        address _governance,
        address _guardian,
        address _rewards,
        string calldata _name,
        string calldata _symbol,
        uint256 _releaseDelta
    ) external returns (address);
}

contract VaultRegistry is OwnableUpgradeable, UUPSUpgradeable {
    enum VaultType {
        DEFAULT,
        AUTOMATED,
        FIXED_TERM,
        EXPERIMENTAL
    } // Could be replaced by a uint.

    address public releaseRegistry;
    // token => type => number => address
    mapping(address => mapping(VaultType => address[])) public vaults;
    // Index of token added => token address
    address[] public tokens;
    // Inclusion check for token
    mapping(address => bool) public isRegistered;
    mapping(address => bool) public approvedVaultsOwner;

    mapping(address => string) public tags;
    mapping(address => bool) public banksy;
    mapping(address => bool) public vaultEndorsers;

    event NewRelease(
        uint256 indexed releaseId,
        address template,
        string apiVersion
    );
    event NewVault(
        address indexed token,
        uint256 indexed vaultId,
        VaultType vaultType,
        address vault,
        string apiVersion
    );

    event ApprovedVaultOwnerUpdated(address governance, bool approved);

    event VaultTagged(address vault, string tag);

    event RoleUpdated(address account, bool canTag, bool canEndorse);

    error GovernanceMismatch(address vault);
    error VersionMissmatch(string v1, string v2);
    error EndorseVaultWithSameVersion(address existingVault, address newVault);

    function initialize(address _releaseRegistry) external initializer {
        releaseRegistry = _releaseRegistry;
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override {
        require(msg.sender == owner(), "not allowed");
    }

    function numTokens() external returns (uint256) {
        return tokens.length;
    }

    function numVaults(address _token) external returns (uint256) {
        return vaults[_token][VaultType.DEFAULT].length;
    }

    function numVaults(address _token, VaultType _type)
        external
        returns (uint256)
    {
        return vaults[_token][_type].length;
    }

    /**
     @notice Returns the latest deployed vault for the given token.
     @dev Throws if no vaults are endorsed yet for the given token.
     @param _token The token address to find the latest vault for.
     @return The address of the latest vault for the given token.
     NOTE: Throws if there has not been a deployed vault yet for this token
     */
    function latestVault(address _token) external view returns (address) {
        address[] memory tokenVaults = vaults[_token][VaultType.DEFAULT]; // dev: no vault for token
        return tokenVaults[tokenVaults.length - 1]; // dev: no vault for token
    }

    /**
     @notice Returns the latest deployed vault for the given token.
     @dev Throws if no vaults are endorsed yet for the given token.
     @param _token The token address to find the latest vault for.
     @return The address of the latest vault for the given token.
     NOTE: Throws if there has not been a deployed vault yet for this token
     */
    function latestVault(address _token, VaultType _type)
        external
        view
        returns (address)
    {
        address[] memory tokenVaults = vaults[_token][_type];
        return tokenVaults[tokenVaults.length - 1]; // dev: no vault for token
    }

    function _registerVault(
        address _token,
        address _vault,
        VaultType _type
    ) internal {
        // Check if there is an existing deployment for this token at the particular api version
        // NOTE: This doesn't check for strict semver-style linearly increasing release versions
        uint256 nVaults = vaults[_token][_type].length; // Next id in series
        if (nVaults > 0) {
            if (
                keccak256(
                    bytes(
                        IVault(vaults[_token][_type][nVaults - 1]).apiVersion()
                    )
                ) == keccak256(bytes(IVault(_vault).apiVersion()))
            ) {
                revert EndorseVaultWithSameVersion(
                    vaults[_token][_type][nVaults - 1],
                    _vault
                );
            }
        }

        // Update the latest deployment
        vaults[_token][_type].push(_vault);

        // Register tokens for endorsed vaults
        if (isRegistered[_token] == false) {
            isRegistered[_token] = true;
            tokens.push(_token);
        }
        emit NewVault(
            _token,
            nVaults,
            _type,
            _vault,
            IVault(_vault).apiVersion()
        );
    }

    /**
     @notice
         Adds an existing vault to the list of "endorsed" vaults for that token.
     @dev
         `governance` is set in the new vault as `governance`, with no ability to override.
         Throws if caller isn't `governance`.
         Throws if `vault`'s governance isn't `governance`.
         Throws if no releases are registered yet.
         Throws if `vault`'s api version does not match latest release.
         Throws if there already is a deployment for the vault's token with the latest api version.
         Emits a `NewVault` event.
     @param _vault The vault that will be endorsed by the Registry.
     @param _releaseDelta Specify the number of releases prior to the latest to use as a target. Default is latest.
    */
    function endorseVault(
        address _vault,
        uint256 _releaseDelta,
        VaultType _type
    ) public {
        require(vaultEndorsers[msg.sender], "unauthorized");
        if (approvedVaultsOwner[IVault(_vault).governance()] == false) {
            revert GovernanceMismatch(_vault);
        }

        // NOTE: Underflow if no releases created yet, or targeting prior to release history
        uint256 releaseTarget = IReleaseRegistry(releaseRegistry)
            .numReleases() -
            1 -
            _releaseDelta; // dev: no releases
        string memory apiVersion = IVault(
            IReleaseRegistry(releaseRegistry).releases(releaseTarget)
        ).apiVersion();
        if (
            keccak256(bytes((IVault(_vault).apiVersion()))) !=
            keccak256(bytes((apiVersion)))
        ) {
            revert VersionMissmatch(IVault(_vault).apiVersion(), apiVersion);
        }
        // Add to the end of the list of vaults for token
        _registerVault(IVault(_vault).token(), _vault, _type);
    }

    function endorseVault(address _vault, uint256 _releaseDelta) external {
        endorseVault(_vault, _releaseDelta, VaultType.DEFAULT);
    }

    function endorseVault(address _vault) external {
        endorseVault(_vault, 0, VaultType.DEFAULT);
    }

    /**
     @notice
         Adds existing vaults to the list of "endorsed" vaults for that token.
         Vaults must share the same release delta.
     @dev
         `governance` is set in the new vault as `governance`, with no ability to override.
         Throws if caller isn't `governance`.
         Throws if `vault`'s governance isn't `governance`.
         Throws if no releases are registered yet.
         Throws if `vault`'s api version does not match latest release.
         Throws if there already is a deployment for the vault's token with the latest api version.
         Emits a `NewVault` event.
     @param _vaults The vaults that will be endorsed by the Registry.
     @param _releaseDelta Specify the number of releases prior to the latest to use as a target. Default is latest.
    */
    function batchEndorseVault(
        address[] calldata _vaults,
        uint256 _releaseDelta,
        VaultType _type
    ) external onlyOwner {
        uint256 releaseTarget = IReleaseRegistry(releaseRegistry)
            .numReleases() -
            1 -
            _releaseDelta; // dev: no releases

        string memory apiVersion = IVault(
            IReleaseRegistry(releaseRegistry).releases(releaseTarget)
        ).apiVersion();

        for (uint256 i = 0; i < _vaults.length; ++i) {
            address vault = _vaults[i];
            if (approvedVaultsOwner[IVault(vault).governance()] == false) {
                revert GovernanceMismatch(vault);
            }

            if (
                keccak256(bytes((IVault(vault).apiVersion()))) !=
                keccak256(bytes((apiVersion)))
            ) {
                revert VersionMissmatch(IVault(vault).apiVersion(), apiVersion);
            }
            _registerVault(IVault(vault).token(), vault, _type);
        }
    }

    function newVault(
        address _token,
        address _guardian,
        address _rewards,
        string calldata _name,
        string calldata _symbol,
        uint256 _releaseDelta
    ) external returns (address) {
        return
            newVault(
                _token,
                msg.sender,
                _guardian,
                _rewards,
                _name,
                _symbol,
                _releaseDelta,
                VaultType.DEFAULT
            );
    }

    /**
    @notice
        Create a new vault for the given token using the latest release in the registry,
        as a simple "forwarder-style" delegatecall proxy to the latest release. Also adds
        the new vault to the list of "endorsed" vaults for that token.
    @dev
        `governance` is set in the new vault as `governance`, with no ability to override.
        Throws if caller isn't `governance`.
        Throws if no releases are registered yet.
        Throws if there already is a registered vault for the given token with the latest api version.
        Emits a `NewVault` event.
    @param _token The token that may be deposited into the new Vault.
    @param _guardian The address authorized for guardian interactions in the new Vault.
    @param _rewards The address to use for collecting rewards in the new Vault
    @param _name Specify a custom Vault name. Set to empty string for default choice.
    @param _symbol Specify a custom Vault symbol name. Set to empty string for default choice.
    @param _releaseDelta Specify the number of releases prior to the latest to use as a target. Default is latest.
    @return The address of the newly-deployed vault
     */
    function newVault(
        address _token,
        address _governance,
        address _guardian,
        address _rewards,
        string calldata _name,
        string calldata _symbol,
        uint256 _releaseDelta,
        VaultType _type
    ) public returns (address) {
        require(vaultEndorsers[msg.sender], "unauthorized");
        require(approvedVaultsOwner[_governance], "not allowed vault owner");
        address vault = IReleaseRegistry(releaseRegistry).newVault(
            _token,
            _governance,
            _guardian,
            _rewards,
            _name,
            _symbol,
            _releaseDelta
        );
        _registerVault(_token, vault, _type);
        return vault;
    }

    /**
    @notice Set the ability of a particular tagger to tag current vaults.
    @dev Throws if caller is not `governance`.
    @param _addr The address to approve or deny access.
    @param _tag Allowed to tag
    @param _endorse Allowed to endorse
     */
    function setRole(
        address _addr,
        bool _tag,
        bool _endorse
    ) external onlyOwner {
        banksy[_addr] = _tag;
        vaultEndorsers[_addr] = _endorse;
        emit RoleUpdated(_addr, _tag, _endorse);
    }

    function setApprovedVaultsOwner(address _governance, bool _approved)
        external
        onlyOwner
    {
        approvedVaultsOwner[_governance] = _approved;
        emit ApprovedVaultOwnerUpdated(_governance, _approved);
    }

    /**
    @notice Tag a Vault with a message.
    @dev
        Throws if caller is not `governance` or an approved tagger.
        Emits a `VaultTagged` event.
    @param _vault The address to tag with the given `tag` message.
    @param _tag The message to tag `vault` with.
    */
    function tagVault(address _vault, string calldata _tag) external {
        require(banksy[msg.sender], "not banksy");
        tags[_vault] = _tag;
        emit VaultTagged(_vault, _tag);
    }
}
