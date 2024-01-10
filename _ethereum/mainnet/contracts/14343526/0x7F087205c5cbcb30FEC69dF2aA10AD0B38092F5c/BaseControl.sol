// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";

//  Pellar 2022

abstract contract BaseControl is Ownable {
  // variables
  bool public saleActive;
  bool public tokenPaused;

  address public signerAccount = 0x046c2c915d899D550471d0a7b4d0FaCF79Cde290;
  string public hashKey = "snipe-drp";

  string public defaultURI;
  string public baseURI;

  // verified
  function toggleSale(bool _status) external onlyOwner {
    saleActive = _status;
  }

  // verified
  function setTokenPaused(bool _status) external onlyOwner {
    tokenPaused = _status;
  }

  // verified
  function setSignerInfo(address _signer) external onlyOwner {
    signerAccount = _signer;
  }

  // verified
  function setHashKey(string calldata _hashKey) external onlyOwner {
    hashKey = _hashKey;
  }

  // verified
  function setDefaultURI(string calldata _uri) external onlyOwner {
    defaultURI = _uri;
  }

  // verified
  function setBaseURI(string calldata _uri) external onlyOwner {
    baseURI = _uri;
  }

  // verified
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /** Internal */
  // verified
  function isBlank(string memory _string) internal pure returns (bool) {
    return bytes(_string).length == 0;
  }

  // verified
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

  // verified
  function validSignature(bytes32 _message, bytes memory _signature) internal view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s) == signerAccount;
  }
}
