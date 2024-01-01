// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC1155Holder.sol";
import "./ERC721Holder.sol";
import "./IEns.sol";
import "./IReverseRegistrar.sol";
import "./INameWrapper.sol";
import "./LibDiamond.sol";

contract Ens is IEns, ERC1155Holder, ERC721Holder {
  function ensSetReverseName(address reverseRegistrar, string memory name) external {
    LibDiamond.enforceIsContractOwner();

    IReverseRegistrar(reverseRegistrar).setName(name);
  }

  function ensUnwrap(address nameWrapper, bytes32 labelHash) external {
    LibDiamond.enforceIsContractOwner();

    INameWrapper(nameWrapper).unwrapETH2LD(labelHash, address(this), address(this));
  }
}
