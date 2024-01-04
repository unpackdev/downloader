// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import "./Ownable.sol";
import "./IProxyManagerAccessControl.sol";
import "./IDelegateCallProxyManager.sol";


contract ProxyManagerAccessControl is IProxyManagerAccessControl, Ownable {
/* ==========  Storage  ========== */

  mapping (address => bool) public override hasAdminAccess;
  address public immutable override proxyManager;

/* ==========  Modifiers  ========== */

  modifier onlyAdminOrOwner {
    require(
      hasAdminAccess[msg.sender] || msg.sender == owner(),
      "ERR_NOT_ADMIN_OR_OWNER"
    );
    _;
  }

/* ==========  Constructor  ========== */

  constructor(address proxyManager_) public Ownable() {
    proxyManager = proxyManager_;
  }

/* ==========  Admin Controls  ========== */

  /**
   * @dev Allows `deployer` to deploy many-to-one proxies.
   */
  function approveDeployer(address deployer) external override onlyAdminOrOwner {
    IDelegateCallProxyManager(proxyManager).approveDeployer(deployer);
  }

  /**
   * @dev Creates a many-to-one proxy relationship.
   *
   * Deploys an implementation holder contract which stores the
   * implementation address for many proxies. The implementation
   * address can be updated on the holder to change the runtime
   * code used by all its proxies.
   *
   * @param implementationID ID for the implementation, used to identify the
   * proxies that use it. Also used as the salt in the create2 call when
   * deploying the implementation holder contract.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  )
    external
    override
    onlyAdminOrOwner
  {
    IDelegateCallProxyManager(proxyManager).createManyToOneProxyRelationship(
      implementationID,
      implementation
    );
  }

/* ==========  Owner Controls  ========== */

  /**
   * @dev Grants admin access to `admin`.
   */
  function grantAdminAccess(address admin) external override onlyOwner {
    hasAdminAccess[admin] = true;
    emit AdminAccessGranted(admin);
  }

  /**
   * @dev Revokes admin access from `admin`.
   */
  function revokeAdminAccess(address admin) external override onlyOwner {
    hasAdminAccess[admin] = false;
    emit AdminAccessRevoked(admin);
  }

  /**
   * @dev Prevents `deployer` from deploying many-to-one proxies.
   */
  function revokeDeployerApproval(address deployer) external override onlyOwner {
    IDelegateCallProxyManager(proxyManager).revokeDeployerApproval(deployer);
  }

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationManyToOne(bytes32 implementationID)
    external
    override
    onlyOwner
  {
    IDelegateCallProxyManager(proxyManager).lockImplementationManyToOne(
      implementationID
    );
  }

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationOneToOne(address proxyAddress)
    external
    override
    onlyOwner
  {
    IDelegateCallProxyManager(proxyManager).lockImplementationOneToOne(
      proxyAddress
    );
  }

  /**
   * @dev Updates the implementation address for a many-to-one
   * proxy relationship.
   *
   * @param implementationID Identifier for the implementation.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  )
    external
    override
    onlyOwner
  {
    IDelegateCallProxyManager(proxyManager).setImplementationAddressManyToOne(
      implementationID,
      implementation
    );
  }

  /**
   * @dev Updates the implementation address for a one-to-one proxy.
   *
   * Note: This could work for many-to-one as well if the caller
   * provides the implementation holder address in place of the
   * proxy address, as they use the same access control and update
   * mechanism.
   *
   * @param proxyAddress Address of the deployed proxy
   * @param implementation Address with the runtime code for
   * the proxy to use.
   */
  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  )
    external
    override
    onlyOwner
  {
    IDelegateCallProxyManager(proxyManager).setImplementationAddressOneToOne(
      proxyAddress,
      implementation
    );
  }

  /**
   * @dev Transfers ownership of the proxy manager to a new account.
   */
  function transferManagerOwnership(address newOwner) external override onlyOwner {
    Ownable(proxyManager).transferOwnership(newOwner);
  }

/* ==========  Proxy Deployment  ========== */

  /**
   * @dev Deploy a proxy contract with a one-to-one relationship
   * with its implementation.
   *
   * The proxy will have its own implementation address which can
   * be updated by the proxy manager.
   *
   * @param suppliedSalt Salt provided by the account requesting deployment.
   * @param implementation Address of the contract with the runtime
   * code that the proxy should use.
   */
  function deployProxyOneToOne(
    bytes32 suppliedSalt,
    address implementation
  )
    external
    override
    onlyAdminOrOwner
    returns(address)
  {
    return IDelegateCallProxyManager(proxyManager).deployProxyOneToOne(
      suppliedSalt,
      implementation
    );
  }

  /**
   * @dev Deploy a proxy with a many-to-one relationship with its implemenation.
   *
   * The proxy will call the implementation holder for every transaction to
   * determine the address to use in calls.
   *
   * @param implementationID Identifier for the proxy's implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  )
    external
    override
    onlyAdminOrOwner
    returns(address proxyAddress)
  {
    return IDelegateCallProxyManager(proxyManager).deployProxyManyToOne(
      implementationID,
      suppliedSalt
    );
  }
}