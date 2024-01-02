// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// Import from Core /////
import "./Fyde.sol";

/// Utils /////
import "./Address.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./StorageSlot.sol";

//Interfaces
import "./IERC20.sol";
import "./IGovernanceModule.sol";
import "./SafeERC20.sol";

///@title  ProxyRouter
///@notice Forwards the proxy clone call to the implementation contract. Implements ERC1967.
///@dev    The proxy pattern is a combination of minimal cloning and beacon proxy. The governance
/// module deploys clones
///        that delegateCall to the proxy router which is part of the governance module. The router
/// performs access checks
///        and forwards the call to the implementation contract. ERC1967 enables calling the proxy
/// via the governance module
///        contract on block explorers.
contract ProxyRouter is Ownable {
  using SafeERC20 for IERC20;

  /*//////////////////////////////////////////////////////////////
                              STORAGE
  //////////////////////////////////////////////////////////////*/

  ///@notice Storage slot with the address of the proxy implementation.
  ///@dev This is the keccak-256 hash of "eip1967.proxy.implementation" - 1
  bytes32 internal constant _IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  ///@notice address of the governance module
  address immutable GOVERNANCE_MODULE;

  ///@notice proxy version tracking
  uint256 public proxyVersion;

  /*//////////////////////////////////////////////////////////////
                               EVENT
  //////////////////////////////////////////////////////////////*/

  event Upgraded(address indexed implementation);

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor() Ownable(msg.sender) {
    GOVERNANCE_MODULE = address(this);
  }

  /*//////////////////////////////////////////////////////////////
                              EXTERNAL
  //////////////////////////////////////////////////////////////*/

  ///@notice Called by the governance module in order to transfer assets for rebalancing purpose
  ///@param _asset asset address
  ///@param _amount number of token
  ///@dev   Will be executed by the proxy via a delegate call to the governance module
  function transferAssetToFyde(address _asset, uint256 _amount) external {
    if (msg.sender != GOVERNANCE_MODULE) revert Unauthorized();
    IERC20(_asset).safeTransfer(IGovernanceModule(GOVERNANCE_MODULE).fyde(), _amount);
  }

  ///@notice Updates proxy to new implementation address
  ///@param  _newImplementation Address of the new implementation
  function updateProxyImplementation(address _newImplementation) external onlyOwner {
    require(Address.isContract(_newImplementation), "ERC1967: new implementation is not a contract");
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _newImplementation;
    proxyVersion += 1;
    emit Upgraded(_newImplementation);
  }

  ///@notice The implementation address of the governance proxy
  ///@dev    Storage slot according to ERC1967
  function proxyImplementation() public view returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  /*//////////////////////////////////////////////////////////////
                               INTERNAL
  //////////////////////////////////////////////////////////////*/

  ///@dev Delegates calls to the implementation contract. The governance module serves as a beacon
  /// which stores the
  ///     implementation, in order to have upgradability of all proxies at once. Since the function
  /// will be delegate called
  ///     by a proxy, the implementation has to be read via external call to governance module.
  function _delegateToImplementation() internal {
    address implementation = IGovernanceModule(GOVERNANCE_MODULE).proxyImplementation();
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
      // execute function call using the implementation
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }
}
