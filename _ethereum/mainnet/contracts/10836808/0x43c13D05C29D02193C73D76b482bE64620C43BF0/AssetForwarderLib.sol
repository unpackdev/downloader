// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./AssetForwarder.sol";
import "./Create2.sol";
import "./FactoryLib.sol";
import "./ShifterPool.sol";

library AssetForwarderLib {
  bytes32 constant ASSET_FORWARDER_IMPLEMENTATION_SALT = 0x6b6f6b75258f8f4cdb6ef275682bc2be3e8b970e5e4417113bd1ea53622d907e; // keccak("asset-forwarder-implementation")
  function GET_ASSET_FORWARDER_IMPLEMENTATION_SALT() internal pure returns (bytes32) {
    return ASSET_FORWARDER_IMPLEMENTATION_SALT;
  }
  function deployAssetForwarder() internal returns (address output) {
    output = Create2.deploy(0, ASSET_FORWARDER_IMPLEMENTATION_SALT, type(AssetForwarder).creationCode);
  }
  function deployAssetForwarderClone(address target, bytes32 salt) internal returns (address output) {
    output = FactoryLib.create2Clone(target, uint256(salt));
  }
  function deriveAssetForwarderAddress(address payable shifterPool, address from, bytes32 salt) internal view returns (address) {
    return FactoryLib.deriveInstanceAddress(shifterPool, ShifterPool(shifterPool).getAssetForwarderImplementationHandler(), keccak256(abi.encodePacked(GET_ASSET_FORWARDER_IMPLEMENTATION_SALT(), from, salt)));
  }
}
