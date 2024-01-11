// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

library TokenUriStorage {
  struct Layout {
    // storage for base URI
    string baseURI;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256('citydao.contracts.storage.TokenUri');

  //noinspection NoReturn
  function layout() internal pure returns (Layout storage _layout) {
    bytes32 slot = STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      _layout.slot := slot
    }
  }

  function baseURI() internal view returns (string memory) {
    return layout().baseURI;
  }

  function setBaseURI(string memory _baseURI) internal {
    layout().baseURI = _baseURI;
  }
}
