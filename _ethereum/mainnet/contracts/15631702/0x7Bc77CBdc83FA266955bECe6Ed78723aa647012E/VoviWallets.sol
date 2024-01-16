// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./Counters.sol";
import "./IVoviWallets.sol";

contract VoviWallets is IVoviWallets {
  using Counters for Counters.Counter;

  Counters.Counter private _pointer;
  mapping(address => uint256) private _pointers;
  mapping(uint256 => address[]) private _linkedWallets;
  mapping(address => bool) private _hasLink;
  mapping(address => mapping(address => bool)) private _pendingLinks;

  constructor () {

  }

  function isOwnerOf(Link[] calldata links, address token, uint256 tokenId) external view returns (bool) {
    require(this.confirmLinks(links), "VOVI Wallets: Cannot confirm wallet linking");
    IERC721 tokenContract = IERC721(token);
    address owner = tokenContract.ownerOf(tokenId);
    for (uint256 i = 0; i < links.length; i++) {
      if (links[i].signer == owner) {
        return true;
      }
    }
    return false;
  }

  function balanceOf(Link[] calldata links, address token) external view returns (uint256) {
    require(this.confirmLinks(links), "VOVI Wallets: Cannot confirm wallet linking");
    uint256 balance = 0;
    IERC721 tokenContract = IERC721(token);
    for (uint256 i = 0; i < links.length; i++) {
      balance += tokenContract.balanceOf(links[i].signer);
    }
    return balance;
  }

  function confirmLinks(Link[] calldata links) external pure returns (bool) {
    if (links.length == 0) {
      return false;
    }
    for (uint256 i = 0; i < links.length; i++) {
      if (recoverSigner(getEthSignedHash(getMessageHash("VOVI Linked Wallet")), links[i].signature) != links[i].signer) {
        return false;
      }
    }
    return true;
  }

  function getMessageHash(string memory message) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(message));
  }

  function getEthSignedHash(bytes32 messageHash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      messageHash
    ));
  }

  function recoverSigner(bytes32 ethSignedMessageHash, bytes memory sig) internal pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = _split(sig);
    return ecrecover(ethSignedMessageHash, v, r, s);
  }

  function _split(bytes memory _sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(_sig.length == 65, "Invalid Signature Length");
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
  }
}