// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.22;

import "./ERC1967Proxy.sol";
import "./IEthVaultFactory.sol";
import "./IEthVault.sol";
import "./IVaultsRegistry.sol";
import "./OwnMevEscrow.sol";

/**
 * @title EthVaultFactory
 * @author StakeWise
 * @notice Factory for deploying Ethereum staking Vaults
 */
contract EthVaultFactory is IEthVaultFactory {
  IVaultsRegistry internal immutable _vaultsRegistry;

  /// @inheritdoc IEthVaultFactory
  address public immutable override implementation;

  /// @inheritdoc IEthVaultFactory
  address public override ownMevEscrow;

  /// @inheritdoc IEthVaultFactory
  address public override vaultAdmin;

  /**
   * @dev Constructor
   * @param _implementation The implementation address of Vault
   * @param vaultsRegistry The address of the VaultsRegistry contract
   */
  constructor(address _implementation, IVaultsRegistry vaultsRegistry) {
    implementation = _implementation;
    _vaultsRegistry = vaultsRegistry;
  }

  /// @inheritdoc IEthVaultFactory
  function createVault(
    bytes calldata params,
    bool isOwnMevEscrow
  ) external payable override returns (address vault) {
    // create vault
    vault = address(new ERC1967Proxy(implementation, ''));

    // create MEV escrow contract if needed
    address _mevEscrow;
    if (isOwnMevEscrow) {
      _mevEscrow = address(new OwnMevEscrow(vault));
      // set MEV escrow contract so that it can be initialized in the Vault
      ownMevEscrow = _mevEscrow;
    }

    // set admin so that it can be initialized in the Vault
    vaultAdmin = msg.sender;

    // initialize Vault
    IEthVault(vault).initialize{value: msg.value}(params);

    // cleanup MEV escrow contract
    if (isOwnMevEscrow) delete ownMevEscrow;

    // cleanup admin
    delete vaultAdmin;

    // add vault to the registry
    _vaultsRegistry.addVault(vault);

    // emit event
    emit VaultCreated(msg.sender, vault, _mevEscrow, params);
  }
}
