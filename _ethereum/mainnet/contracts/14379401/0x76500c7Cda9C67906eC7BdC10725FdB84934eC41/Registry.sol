// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "./IBridge.sol";
import "./IVault.sol";
import "./IRegistry.sol";
import "./IEverscale.sol";

import "./Ownable.sol";
import "./ProxyAdmin.sol";
import "./TransparentUpgradeableProxy.sol";


contract Registry is Ownable, IRegistry, IEverscale {
    // len(vaultReleases)
    uint256 public numVaultReleases;
    mapping(uint256 => address) public vaultReleases;

    // Token => len(vaults)
    mapping(address => uint256) public numVaults;
    mapping(address => mapping(uint256 => address)) vaults;

    // Index of token added => token address
    mapping(uint256 => address) tokens;
    // len(tokens)
    uint256 public numTokens;
    // Inclusion check for token
    mapping(address => bool) public isRegistered;

    address public bridge;
    address public proxyAdmin;
    EverscaleAddress public rewards;

    mapping(address => string) public tags;
    mapping(address => bool) public banksy;

    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    constructor(
        address _bridge,
        address _proxyAdmin
    ) {
        bridge = _bridge;
        proxyAdmin = _proxyAdmin;
    }

    function setBridge(
        address _bridge
    ) external onlyOwner {
        bridge = _bridge;
    }

    function setRewards(
        EverscaleAddress memory _rewards
    ) external onlyOwner {
        rewards = _rewards;
    }

    function setProxyAdmin(
        address _proxyAdmin
    ) external onlyOwner {
        proxyAdmin = _proxyAdmin;
    }

    function latestVaultRelease()
        external
        view
    returns(
        string memory api_version
    ) {
        return IVault(vaultReleases[numVaultReleases - 1]).apiVersion();
    }

    function latestVault(
        address token
    )
        external
        view
    returns(
        address
    ) {
        return vaults[token][numVaults[token] - 1];
    }

    function newVaultRelease(
        address vault
    ) external onlyOwner {
        uint256 vault_release_id = numVaultReleases;

        if (vault_release_id > 0) {
            require(
                !compareStrings(
                IVault(vaultReleases[vault_release_id - 1]).apiVersion(),
                IVault(vault).apiVersion()
            ),
                "Registry: new vault release should have different api version"
            );
        }

        vaultReleases[vault_release_id] = vault;
        numVaultReleases = vault_release_id + 1;

        emit NewVaultRelease(vault_release_id, vault, IVault(vault).apiVersion());
    }

    function _newProxyVault(
        address token,
        address governance,
        uint256 vault_release_target
    ) internal returns (address) {
        address vault_release = vaultReleases[vault_release_target];

        require(vault_release != address(0), "Registry: vault release target is wrong");

        // Deploy Vault release proxy, owned by proxy admin
        TransparentUpgradeableProxy vault = new TransparentUpgradeableProxy(
            vault_release,
            proxyAdmin,
            ""
        );

        // Initialize Vault
        IVault(address(vault)).initialize(
            bridge,
            governance,
            token,
            rewards
        );

        return address(vault);
    }

    function _registerVault(
        address token,
        address vault
    ) internal {
        uint256 vault_id = numVaults[token];

        if (vault_id > 0) {
            require(
                !compareStrings(
                IVault(vaults[token][vault_id - 1]).apiVersion(),
                IVault(vault).apiVersion()
            ),
                "Registry: new vault should have different api version"
            );
        }

        vaults[token][vault_id] = vault;
        numVaults[token] = vault_id + 1;

        if (!isRegistered[token]) {
            isRegistered[token] = true;
            tokens[numTokens] = token;
            numTokens += 1;
        }

        emit NewVault(token, vault_id, vault, IVault(vault).apiVersion());
    }

    function newVault(
        address token,
        uint256 vaultReleaseDelta
    ) external onlyOwner returns (address) {
        uint256 vault_release_target = numVaultReleases - 1 - vaultReleaseDelta;

        address vault = _newProxyVault(
            token,
            msg.sender,
            vault_release_target
        );

        _registerVault(token, vault);

        return vault;
    }

    function newExperimentalVault(
        address token,
        address governance,
        uint256 vaultReleaseDelta
    ) external returns (address) {
        uint256 vault_release_target = numVaultReleases - 1 - vaultReleaseDelta;

        address vault = _newProxyVault(
            token,
            governance,
            vault_release_target
        );

        emit NewExperimentalVault(
            token,
            msg.sender,
            vault,
            IVault(vault).apiVersion()
        );

        return vault;
    }

    function endorseVault(
        address vault,
        uint256 vaultReleaseDelta
    ) external onlyOwner {
        require(
            IVault(vault).governance() == msg.sender,
            "Registry: wrong vault governance"
        );

        uint256 vault_release_target = numVaultReleases - 1 - vaultReleaseDelta;
        string memory vault_api_version = IVault(vaultReleases[vault_release_target]).apiVersion();

        require(
            compareStrings(IVault(vault).apiVersion(), vault_api_version),
            "Registry: vault should have same api version as specified release"
        );

        _registerVault(IVault(vault).token(), vault);
    }

    function setBanksy(
        address tagger,
        bool allowed
    ) external onlyOwner {
        banksy[tagger] = allowed;
    }

    function tagVault(
        address vault,
        string memory tag
    ) external {
        if (msg.sender != owner()) {
            require(
                banksy[msg.sender],
                "Registry: only owner or banksy are allowed to tag"
            );
        }

        tags[vault] = tag;
        emit VaultTagged(vault, tag);
    }
}
