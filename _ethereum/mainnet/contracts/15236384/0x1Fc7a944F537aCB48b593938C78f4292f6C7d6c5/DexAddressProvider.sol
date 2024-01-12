// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IDexAddressProvider.sol";
import "./IAddressProvider.sol";

contract DexAddressProvider is IDexAddressProvider {
  IAddressProvider public immutable override a;

  mapping(uint256 => Dex) private _dexMapping;

  modifier onlyManager() {
    IAccessController controller = a.controller();
    require(controller.hasRole(controller.MANAGER_ROLE(), msg.sender), "LM010");
    _;
  }

  constructor(IAddressProvider _a, Dex[] memory dexes) public {
    require(address(_a) != address(0), "LM000");
    a = _a;
    for (uint256 i = 0; i < dexes.length; i++) {
      _dexMapping[i] = dexes[i];
    }
  }

  /**
    Set the dex address for dexMapping
    @dev only manager or address(this) can call this method.
    @param _index the index for the dex.
    @param _proxy the address for the proxy.
    @param _router the address for the router.
  */
  function setDexMapping(
    uint256 _index,
    address _proxy,
    address _router
  ) external override onlyManager {
    require(_proxy != address(0), "LM000");
    require(_router != address(0), "LM000");
    _dexMapping[_index] = Dex({ proxy: _proxy, router: _router });
    emit DexSet(_index, _proxy, _router);
  }

  /** 
    Returns proxy and router address for a specific dex index
    @param index the index for the dex
    @return (proxy address, router address)
  */
  function getDex(uint256 index) external view override returns (address, address) {
    Dex memory dex = _dexMapping[index];
    return (dex.proxy, dex.router);
  }
}
