// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

import "./IBridge.sol";
import "./IVault.sol";
import "./IRegistry.sol";
import "./IVaultWrapper.sol";

import "./Ownable.sol";
import "./ProxyAdmin.sol";
import "./TransparentUpgradeableProxy.sol";
import "./Clones.sol";


contract Registry is Ownable, IRegistry {
    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    // len(vaultReleases)
    uint256 public numVaultReleases;
    mapping(uint256 => address) public vaultReleases;
    // len(wrapperReleases)
    uint256 public numWrapperReleases;
    mapping(uint256 => address) public wrapperReleases;
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

    function latestWrapperRelease()
        external
        view
    returns (
        string memory api_version
    ) {
        return IVaultWrapper(vaultReleases[numVaultReleases - 1]).apiVersion();
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

    function newWrapperRelease(
        address wrapper
    ) external onlyOwner {
        uint256 wrapper_release_id = numWrapperReleases;

        if (wrapper_release_id > 0) {
            require(
                !compareStrings(
                IVaultWrapper(wrapperReleases[wrapper_release_id - 1]).apiVersion(),
                IVaultWrapper(wrapper).apiVersion()
            ),
                "Registry: new wrapper release should have different api version"
            );
        }

        wrapperReleases[wrapper_release_id] = wrapper;
        numWrapperReleases = wrapper_release_id + 1;

        emit NewWrapperRelease(wrapper_release_id, wrapper, IVaultWrapper(wrapper).apiVersion());
    }

    function _newProxyVault(
        address token,
        address governance,
        address guardian,
        uint256 targetDecimals,
        uint256 vault_release_target,
        uint256 wrapper_release_target
    ) internal returns(address) {
        address vault_release = vaultReleases[vault_release_target];
        address wrapper_release = wrapperReleases[wrapper_release_target];

        require(vault_release != ZERO_ADDRESS, "Registry: vault release target is wrong");
        require(wrapper_release != ZERO_ADDRESS, "Registry: wrapper release target is wrong");

        // Deploy Vault release proxy, owned by proxy admin
        TransparentUpgradeableProxy vault = new TransparentUpgradeableProxy(
            vault_release,
            proxyAdmin,
            ""
        );

        // Deploy wrapper proxy
        TransparentUpgradeableProxy wrapper = new TransparentUpgradeableProxy(
            wrapper_release,
            proxyAdmin,
            ""
        );

        // Initialize wrapper
        IVaultWrapper(address(wrapper)).initialize(
            address(vault)
        );

        // Initialize Vault
        IVault(address(vault)).initialize(
            token,
            governance,
            bridge,
            address(wrapper),
            guardian,
            ZERO_ADDRESS,
            targetDecimals
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
        address guardian,
        uint256 targetDecimals,
        uint256 vaultReleaseDelta,
        uint256 wrapperReleaseDelta
    ) external onlyOwner returns (address) {
        uint256 vault_release_target = numVaultReleases - 1 - vaultReleaseDelta;
        uint256 wrapper_release_target = numWrapperReleases - 1 - wrapperReleaseDelta;

        address vault = _newProxyVault(
            token,
            msg.sender,
            guardian,
            targetDecimals,
            vault_release_target,
            wrapper_release_target
        );

        _registerVault(token, vault);

        return vault;
    }

    function newExperimentalVault(
        address token,
        address governance,
        address guardian,
        uint256 targetDecimals,
        uint256 vaultReleaseDelta,
        uint256 wrapperReleaseDelta
    ) external returns(address) {
        uint256 vault_release_target = numVaultReleases - 1 - vaultReleaseDelta;
        uint256 wrapper_release_target = numWrapperReleases - 1 - wrapperReleaseDelta;

        address vault = _newProxyVault(
            token,
            governance,
            guardian,
            targetDecimals,
            vault_release_target,
            wrapper_release_target
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
        uint256 vaultReleaseDelta,
        uint256 wrapperReleaseDelta
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

        uint256 wrapper_release_target = numWrapperReleases - 1 - wrapperReleaseDelta;
        string memory wrapper_api_version = IVaultWrapper(wrapperReleases[wrapper_release_target]).apiVersion();

        address wrapper = IVault(vault).wrapper();

        require(
            compareStrings(IVaultWrapper(wrapper).apiVersion(), wrapper_api_version),
            "Registry: wrapper should have same api version as specified release"
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
