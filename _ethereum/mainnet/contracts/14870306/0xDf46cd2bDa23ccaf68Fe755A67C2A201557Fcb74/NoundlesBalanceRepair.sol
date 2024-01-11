// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Holder.sol";

import "./INoundles.sol";

contract NoundlesBalanceRepair is Ownable, ERC721Holder {
  INoundles private _noundles;
  uint256 private _noundleTokenId;

  constructor(address noundlesAddress) {
    _noundles = INoundles(noundlesAddress);
  }

  function needsRepair(address account) external view returns (bool) {
    uint256 realBalance = _noundles.balanceOf(account);
    uint256 noundleBalance = _noundles.noundleBalance(account);

    return realBalance != noundleBalance;
  }

  function repairNoundleBalance(address account) external {
    require(
      _noundles.isApprovedForAll(account, address(this)),
      'Repair contract must be approved'
    );

    uint256 realBalance = _noundles.balanceOf(account);
    uint256 noundleBalance = _noundles.noundleBalance(account);

    if (realBalance > noundleBalance) {
      _incrementNoundleBalance(account, realBalance - noundleBalance);
    } else {
      _decrementNoundleBalance(account, noundleBalance - realBalance);
    }
  }

  function _incrementNoundleBalance(address account, uint256 count) internal {
    for (uint256 i; i < count; ++i) {
      _noundles.safeTransferFrom(address(this), account, _noundleTokenId);
      _noundles.transferFrom(account, address(this), _noundleTokenId);
    }
  }

  function _decrementNoundleBalance(address account, uint256 count) internal {
    for (uint256 i; i < count; ++i) {
      _noundles.transferFrom(address(this), account, _noundleTokenId);
      _noundles.safeTransferFrom(account, address(this), _noundleTokenId);
    }
  }

  function setNoundlesAddress(address noundlesAddress) external onlyOwner {
    _noundles = INoundles(noundlesAddress);
  }

  // set id of token to transfer during balance repair
  function setNoundleTokenId(uint256 tokenId) external onlyOwner {
    _noundleTokenId = tokenId;
  }

  function withdrawNoundles(address to, uint256[] calldata tokenIds)
    external
    onlyOwner
  {
    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      _noundles.transferFrom(address(this), to, tokenIds[i]);
    }
  }
}
