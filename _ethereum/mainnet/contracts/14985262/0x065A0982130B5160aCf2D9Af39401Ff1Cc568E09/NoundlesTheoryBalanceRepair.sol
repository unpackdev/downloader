// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Holder.sol";
import "./ECDSA.sol";

import "./INoundlesTheory.sol";

contract NoundlesTheoryBalanceRepair is Ownable, ERC721Holder {
  INoundlesTheory private _noundlesTheory;
  uint256 private _companionTokenId;
  uint256 private _evilNoundleTokenId;
  address private _signerAddress;

  constructor(address noundlesTheoryAddress) {
    _noundlesTheory = INoundlesTheory(noundlesTheoryAddress);
  }

  function repairCompanionBalance(
    address account,
    uint256 realBalance,
    bytes calldata signature
  ) external {
    require(
      _noundlesTheory.isApprovedForAll(account, address(this)),
      'Repair contract must be approved'
    );
    require(
      _validateSignature(account, realBalance, 0, signature),
      'Invalid signature'
    );

    uint256 companionBalance = _noundlesTheory.companionBalance(account);

    if (realBalance > companionBalance) {
      _incrementBalance(
        account,
        realBalance - companionBalance,
        _companionTokenId
      );
    } else {
      _decrementBalance(
        account,
        companionBalance - realBalance,
        _companionTokenId
      );
    }
  }

  function repairEvilBalance(
    address account,
    uint256 realBalance,
    bytes calldata signature
  ) external {
    require(
      _noundlesTheory.isApprovedForAll(account, address(this)),
      'Repair contract must be approved'
    );
    require(
      _validateSignature(account, realBalance, 1, signature),
      'Invalid signature'
    );

    uint256 evilBalance = _noundlesTheory.evilBalance(account);

    if (realBalance > evilBalance) {
      _incrementBalance(
        account,
        realBalance - evilBalance,
        _evilNoundleTokenId
      );
    } else {
      _decrementBalance(
        account,
        evilBalance - realBalance,
        _evilNoundleTokenId
      );
    }
  }

  function _incrementBalance(
    address account,
    uint256 count,
    uint256 tokenId
  ) internal {
    for (uint256 i; i < count; ++i) {
      _noundlesTheory.safeTransferFrom(address(this), account, tokenId);
      _noundlesTheory.transferFrom(account, address(this), tokenId);
    }
  }

  function _decrementBalance(
    address account,
    uint256 count,
    uint256 tokenId
  ) internal {
    for (uint256 i; i < count; ++i) {
      _noundlesTheory.transferFrom(address(this), account, tokenId);
      _noundlesTheory.safeTransferFrom(account, address(this), tokenId);
    }
  }

  function setNoundlesTheoryAddress(address noundlesTheoryAddress)
    external
    onlyOwner
  {
    _noundlesTheory = INoundlesTheory(noundlesTheoryAddress);
  }

  function setSignerAddress(address signerAddress) external onlyOwner {
    _signerAddress = signerAddress;
  }

  // set id of token to transfer during companion balance repair
  function setCompanionTokenId(uint256 tokenId) external onlyOwner {
    require(_noundlesTheory.noundleType(tokenId) == 0, 'Incorrect token type');
    _companionTokenId = tokenId;
  }

  // set id of token to transfer during evil noundle balance repair
  function setEvilNoundleTokenId(uint256 tokenId) external onlyOwner {
    require(_noundlesTheory.noundleType(tokenId) == 1, 'Incorrect token type');
    _evilNoundleTokenId = tokenId;
  }

  function withdrawTokens(address to, uint256[] calldata tokenIds)
    external
    onlyOwner
  {
    uint256 numTokens = tokenIds.length;
    for (uint256 i; i < numTokens; ++i) {
      _noundlesTheory.transferFrom(address(this), to, tokenIds[i]);
    }
  }

  function _validateSignature(
    address account,
    uint256 balance,
    uint8 tokenType,
    bytes calldata signature
  ) internal view returns (bool) {
    bytes32 dataHash = keccak256(abi.encodePacked(account, balance, tokenType));
    bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

    address signer = ECDSA.recover(message, signature);
    return (signer == _signerAddress);
  }
}
