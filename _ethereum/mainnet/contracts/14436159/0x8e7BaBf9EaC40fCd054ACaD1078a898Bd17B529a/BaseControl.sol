// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

abstract contract BaseControl is Ownable {
  // variables
  bool public privateSaleActive;
  bool public publicSaleActive;
  address public signerAccount = 0x8F9Ab1589581250c9D0BA92d3c865E06C9CCfCe0;
  string public hashKey = "metalife-mife";

  function togglePrivateSale(bool _status) external onlyOwner {
    privateSaleActive = _status;
  }

  function togglePublicSale(bool _status) external onlyOwner {
    publicSaleActive = _status;
  }

  function setSignerInfo(address _signer) external onlyOwner {
    signerAccount = _signer;
  }

  function setHashKey(string calldata _hashKey) external onlyOwner {
    hashKey = _hashKey;
  }

  /** Internal */
  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  function validSignature(bytes32 _message, bytes memory _signature) internal view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s) == signerAccount;
  }
}
