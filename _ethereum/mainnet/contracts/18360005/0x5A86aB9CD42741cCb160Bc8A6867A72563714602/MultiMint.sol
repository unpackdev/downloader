// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

import "./IMultiMint.sol";
import "./IRuno.sol";
import "./Type.sol";

contract MultiMint is IMultiMint, AccessControl, ReentrancyGuard {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER");

  // addresses
  address private _owner;
  address private _runoAddress;

  constructor(
    address workerRunoNFT_
  ) {
    require(workerRunoNFT_ != address(0), "Adoption: invalid workerRunoNFT address");
    _grantRole(OWNER_ROLE, _msgSender());

    _runoAddress = workerRunoNFT_;
  }

  function supportsInterface(
    bytes4 interfaceId_
  ) public view override returns (bool) {
    return interfaceId_ == type(IMultiMint).interfaceId ||
        super.supportsInterface(interfaceId_);
  }

  function multiMint(
    address to_,
    uint256 tier_,
    uint256 count_
  ) public onlyRole(OWNER_ROLE) {
    IRuno _runoContract = IRuno(_runoAddress);
    uint256 currentCap = _runoContract.getTierInfo(tier_).totalSupply;
    uint256 currentSupply = _runoContract.getTierInfo(tier_).currentSupply;

    require(currentCap - currentSupply >= count_, "MultiMint: exceed limits");

    // mint
    for (uint256 i = 0; i < count_; i++) {
      _runoContract.mint(to_, tier_);
    }
  }

  function destroy(
    address payable to_
  ) public onlyRole(OWNER_ROLE) {
    selfdestruct(to_);
  }
}