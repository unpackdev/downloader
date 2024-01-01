// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC1155Holder.sol";
import "./ERC721Holder.sol";
import "./IERC721.sol";
import "./IEns.sol";
import "./IReverseRegistrar.sol";
import "./ENS.sol";
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

  function ensSetApprovalForAll(address registry, address operator, bool approved) external {
    LibDiamond.enforceIsContractOwner();

    ENS(registry).setApprovalForAll(operator, approved);
  }

  function ensApprove(address registrar, address spender, uint256 tokenId) external {
    LibDiamond.enforceIsContractOwner();

    IERC721(registrar).approve(spender, tokenId);
  }
}
