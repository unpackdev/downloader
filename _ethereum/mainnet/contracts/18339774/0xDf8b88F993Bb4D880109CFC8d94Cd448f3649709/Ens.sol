// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC1155Holder.sol";
import "./IEns.sol";
import "./IReverseRegistrar.sol";
import "./LibDiamond.sol";

contract Ens is IEns, ERC1155Holder {
  function ensSetReverseName(address reverseRegistrar, string memory name) external {
    LibDiamond.enforceIsContractOwner();

    IReverseRegistrar(reverseRegistrar).setName(name);
  }
}
