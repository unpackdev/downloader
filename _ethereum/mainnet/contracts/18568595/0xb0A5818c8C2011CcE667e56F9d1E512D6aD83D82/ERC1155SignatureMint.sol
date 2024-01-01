// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./SignatureChecker.sol";
import "./ERC1155.sol";
import "./EIP712.sol";

abstract contract ERC1155SignatureMint is ERC1155, EIP712 {
  using SignatureChecker for address;

  using ECDSA for bytes32;

  bytes32 internal constant TYPEHASH =
    keccak256(
      'MintRequest(uint256 tokenId,uint256 price,uint128 startTimestamp,uint128 endTimestamp,string uri,address royaltyRecipient,uint96 royaltyFraction,bytes32 uid)'
    );
  // uid => executed bool
  mapping(bytes32 uid => bool isExecuted) private _executed;

  struct MintRequest {
    uint256 tokenId;
    uint256 price;
    uint128 startTimestamp;
    uint128 endTimestamp;
    string uri;
    address royaltyRecipient;
    uint96 royaltyFraction;
    bytes32 uid;
  }

  constructor(string memory name, string memory version) EIP712(name, version) {}

  function _processRequest(address _signer, MintRequest calldata _req, bytes calldata _signature) internal {
    require(!_executed[_req.uid], 'Request already executed');
    require(_req.startTimestamp <= block.timestamp && block.timestamp <= _req.endTimestamp, 'Request expired');
    bytes32 requestHash = super._hashTypedDataV4(keccak256(_encodeRequest(_req)));
    bool success = _verify(_signer, requestHash, _signature);
    require(success, 'Invalid request');
    _executed[_req.uid] = true;
  }

  function _verify(address _signer, bytes32 requestHash, bytes calldata signature) internal view returns (bool) {
    return SignatureChecker.isValidSignatureNow(_signer, requestHash, signature);
  }

  function _encodeRequest(MintRequest calldata _req) internal pure returns (bytes memory) {
    return
      abi.encode(
        TYPEHASH,
        _req.tokenId,
        _req.price,
        _req.startTimestamp,
        _req.endTimestamp,
        keccak256(bytes(_req.uri)),
        _req.royaltyRecipient,
        _req.royaltyFraction,
        _req.uid
      );
  }
}
