// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./Ownable.sol";

import "./Role.sol";

import "./IConnector.sol";

import "./ConnectorStorage.sol";

/**
 * @title ELYFI Connector
 * @author ELYSIA
 * @notice ELYFI functions through continual interaction among the various participants.
 * In order to link the real assets and the blockchain, unlike the existing DeFi platform,
 * ELYFI has a group of participants in charge of actual legal contracts and maintenance.
 * 1. Collateral service providers are a group of users who sign a collateral contract with
 * a borrower who takes out a real asset-backed loan and borrows cryptocurrencies from the
 * Money Pool based on this contract.
 * 2. The council, such as legal service provider is a corporation that provides
 * legal services such as document review in the context of legal proceedings, consulting,
 * and the provision of documents necessary in the process of taking out loans secured by real assets,
 * In the future, the types of participant groups will be diversified and subdivided.
 * @dev Only admin can add or revoke roles of the ELYFI. The admin account of the connector is strictly
 * managed, and it is to be managed by governance of ELYFI.
 */
contract Connector is IConnector, ConnectorStorage, Ownable {
  constructor() {}

  function addCouncil(address account) external onlyOwner {
    _grantRole(Role.COUNCIL, account);
    emit NewCouncilAdded(account);
  }

  function addCollateralServiceProvider(address account) external onlyOwner {
    _grantRole(Role.CollateralServiceProvider, account);
    emit NewCollateralServiceProviderAdded(account);
  }

  function revokeCouncil(address account) external onlyOwner {
    _revokeRole(Role.COUNCIL, account);
    emit CouncilRevoked(account);
  }

  function revokeCollateralServiceProvider(address account) external onlyOwner {
    _revokeRole(Role.CollateralServiceProvider, account);
    emit CollateralServiceProviderRevoked(account);
  }

  function _grantRole(bytes32 role, address account) internal {
    _roles[role].participants[account] = true;
  }

  function _revokeRole(bytes32 role, address account) internal {
    _roles[role].participants[account] = false;
  }

  function _hasRole(bytes32 role, address account) internal view returns (bool) {
    return _roles[role].participants[account];
  }

  function isCollateralServiceProvider(address account) external view override returns (bool) {
    return _hasRole(Role.CollateralServiceProvider, account);
  }

  function isCouncil(address account) external view override returns (bool) {
    return _hasRole(Role.COUNCIL, account);
  }

  function isMoneyPoolAdmin(address account) external view override returns (bool) {
    return owner() == account;
  }
}
