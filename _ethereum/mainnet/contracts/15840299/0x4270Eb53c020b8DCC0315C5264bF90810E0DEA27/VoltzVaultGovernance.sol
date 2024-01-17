// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.9;

import "./IVoltzVaultGovernance.sol";

import "./VoltzVaultHelper.sol";
import "./ContractMeta.sol";

import "./VaultGovernance.sol";

/// @notice Governance that manages all Voltz Vaults params and can deploy a new Voltz Vault.
contract VoltzVaultGovernance is ContractMeta, IVoltzVaultGovernance, VaultGovernance {
    /// @notice Creates a new contract.
    /// @param internalParams_ Initial Internal Params
    /// @param delayedProtocolParams_ Initial Protocol Params
    constructor(InternalParams memory internalParams_, DelayedProtocolParams memory delayedProtocolParams_)
        VaultGovernance(internalParams_)
    {
        require(address(delayedProtocolParams_.periphery) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        _delayedProtocolParams = abi.encode(delayedProtocolParams_);
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @inheritdoc IVoltzVaultGovernance
    function delayedProtocolParams() public view returns (DelayedProtocolParams memory) {
        // params are initialized in constructor, so cannot be 0
        return abi.decode(_delayedProtocolParams, (DelayedProtocolParams));
    }

    /// @inheritdoc IVoltzVaultGovernance
    function stagedDelayedProtocolParams() external view returns (DelayedProtocolParams memory) {
        if (_stagedDelayedProtocolParams.length == 0) {
            return DelayedProtocolParams({periphery: IPeriphery(address(0))});
        }
        return abi.decode(_stagedDelayedProtocolParams, (DelayedProtocolParams));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || type(IVoltzVaultGovernance).interfaceId == interfaceId;
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @inheritdoc IVoltzVaultGovernance
    function stageDelayedProtocolParams(DelayedProtocolParams calldata params) external {
        require(address(params.periphery) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        _stageDelayedProtocolParams(abi.encode(params));
        emit StageDelayedProtocolParams(tx.origin, msg.sender, params, _delayedProtocolParamsTimestamp);
    }

    /// @inheritdoc IVoltzVaultGovernance
    function commitDelayedProtocolParams() external {
        _commitDelayedProtocolParams();
        emit CommitDelayedProtocolParams(
            tx.origin,
            msg.sender,
            abi.decode(_delayedProtocolParams, (DelayedProtocolParams))
        );
    }

    /// @inheritdoc IVoltzVaultGovernance
    function createVault(
        address[] memory vaultTokens_,
        address owner_,
        address marginEngine_,
        address voltzVaultHelperSingleton_,
        IVoltzVault.InitializeParams memory initializeParams
    ) external override returns (IVoltzVault vault, uint256 nft) {
        address vaddr;
        (vaddr, nft) = _createVault(owner_);
        address voltzVaultHelper_ = Clones.cloneDeterministic(address(voltzVaultHelperSingleton_), bytes32(nft));

        vault = IVoltzVault(vaddr);
        vault.initialize(
            nft,
            vaultTokens_,
            marginEngine_,
            address(abi.decode(_delayedProtocolParams, (DelayedProtocolParams)).periphery),
            voltzVaultHelper_,
            initializeParams
        );

        emit DeployedVault(
            tx.origin,
            msg.sender,
            vaultTokens_,
            abi.encode(marginEngine_, voltzVaultHelper_, initializeParams),
            owner_,
            vaddr,
            nft
        );
    }

    // -------------------  INTERNAL, VIEW  -------------------

    function _contractName() internal pure override returns (bytes32) {
        return bytes32("VoltzVaultGovernance");
    }

    function _contractVersion() internal pure override returns (bytes32) {
        return bytes32("1.0.0");
    }

    // --------------------------  EVENTS  --------------------------

    /// @notice Emitted when new DelayedProtocolParams are staged for commit
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param params New params that were staged for commit
    /// @param when When the params could be committed
    event StageDelayedProtocolParams(
        address indexed origin,
        address indexed sender,
        DelayedProtocolParams params,
        uint256 when
    );
    /// @notice Emitted when new DelayedProtocolParams are committed
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param params New params that are committed
    event CommitDelayedProtocolParams(address indexed origin, address indexed sender, DelayedProtocolParams params);
}
