// SPDX-License-Identifier: MIT

//  CBOX Agent for getting items from given vault
//
//                 ..        .           .    ..
//  @@@@&        &@@@@@@@@@@@@@@@(        @@@@@.
//  @@@@&   .@@@@@@@@@@@@@@@@@@@@@@@@@.   @@@@@.
//  @@@@& @@@@@@@@               @@@@@@@@ @@@@@.
//  @@@@@@@@@@..                    ,@@@@@@@@@@.
//  @@@@@@@@                          .@@@@@@@@.
//  @@@@@@.                             %@@@@@@.
//  @@@@@.                               %@@@@@.
//  @@@@@                                 @@@@@.
// .@@@@&              C-BOX              @@@@@
//  @@@@@            A G E N T            @@@@@.
//  /@@@@,                              .&@@@@..
//   @@@@@/                             @@@@@(
//    %@@@@@..                        .@@@@@.
//     .@@@@@@,.                    #@@@@@@
//       .@@@@@@@@...         . ,@@@@@@@@
//         . @@@@@@@@@@@@@@@@@@@@@@@@&
//               .@@@@@@@@@@@@@@@..
//
//
// @creator:     ConiunIO
// @security:    batuhan@coniun.io
// @author:      Batuhan KATIRCI (@batuhan_katirci)
// @website:     https://coniun.io/

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Pausable.sol";

import "./ECDSA.sol";

error InvalidSignature(string message);
error ExpiredSignature(string message);
error ReceiverMismatch(string message);
error TransferError(string message);
error PermissionError(string message);
error DuplicateEntryError(string message);

contract CBOXAgent is Ownable, Pausable {
  event CBOXClaimed(
    uint256 indexed cboxWeek,
    address indexed owner,
    uint256 indexed passId,
    address contractAddress,
    uint256 tokenId
  );

  using ECDSA for bytes32;

  address private _signerAddress;
  address private _coniunContractAddress;

  // weekIndex -> (passId -> claimed)
  mapping(uint256 => mapping(uint256 => bool)) private _cboxClaims;

  constructor(address signerAddress, address coniunContractAddress) {
    _signerAddress = signerAddress;
    _coniunContractAddress = coniunContractAddress;
  }

  function setSignerAddress(address signerAddress) public onlyOwner {
    _signerAddress = signerAddress;
  }

  function claimToken(
    address vaultAddress,
    address contractAddress,
    uint256 tokenId,
    uint256 passId,
    uint256 cboxWeek,
    bytes memory signature
  ) public whenNotPaused {
    // Disallow contract calls
    if (msg.sender != tx.origin) {
      revert PermissionError("Contract calls is not allowed");
    }

    // Check if cbox already claimed in given week index
    if (_cboxClaims[cboxWeek][passId] == true) {
      revert DuplicateEntryError("This C-BOX is already claimed");
    }

    // Verify signature agaisnt backend signer address
    if (
      verifySignature(
        vaultAddress,
        msg.sender,
        contractAddress,
        tokenId,
        passId,
        cboxWeek,
        signature
      ) != true
    ) {
      revert InvalidSignature("Signature verification failed");
    }

    _cboxClaims[cboxWeek][passId] = true;

    // initiate proxies
    ERC721Proxy proxy = ERC721Proxy(contractAddress);
    ERC721Proxy coniunProxy = ERC721Proxy(_coniunContractAddress);

    // check if msg.sender still owns that eligible cbox
    if (coniunProxy.ownerOf(passId) != msg.sender) {
      revert ReceiverMismatch("C-BOX owner mismatch");
    }

    // call safeTransferFrom to transfer tokenId to msg.sender
    proxy.safeTransferFrom(vaultAddress, msg.sender, tokenId);
    emit CBOXClaimed(cboxWeek, msg.sender, passId, contractAddress, tokenId);
  }

  // management functions

  function pause() public onlyOwner whenNotPaused {
    _pause();
  }

  function unpause() public onlyOwner whenPaused {
    _unpause();
  }

  // internal functions
  function getMessageHash(
    address _vaultAddress,
    address _receiverAddress,
    address _contractAddress,
    uint256 _tokenId,
    uint256 _passId,
    uint256 _cboxWeek
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          _vaultAddress,
          _receiverAddress,
          _contractAddress,
          _tokenId,
          _passId,
          _cboxWeek
        )
      );
  }

  function getEthSignedMessageHash(bytes32 _messageHash)
    private
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
      );
  }

  function verifySignature(
    address _vaultAddress,
    address _receiverAddress,
    address _contractAddress,
    uint256 _tokenId,
    uint256 _passId,
    uint256 _cboxWeek,
    bytes memory signature
  ) private view returns (bool) {
    bytes32 messageHash = getMessageHash(
      _vaultAddress,
      _receiverAddress,
      _contractAddress,
      _tokenId,
      _passId,
      _cboxWeek
    );
    if (_receiverAddress != msg.sender) {
      revert ReceiverMismatch("This signature is not for you");
    }
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
    return recoverSigner(ethSignedMessageHash, signature) == _signerAddress;
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
    private
    pure
    returns (address)
  {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig)
    private
    pure
    returns (
      bytes32 r,
      bytes32 s,
      uint8 v
    )
  {
    if (sig.length != 65) {
      revert InvalidSignature("Signature length is not 65 bytes");
    }
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
  }
}

// for calling erc721 contracts
abstract contract ERC721Proxy {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual;

  function ownerOf(uint256 tokenId) public view virtual returns (address);
}
