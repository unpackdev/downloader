pragma solidity ^0.8.0;

import "./EIP712.sol";

contract rarityCheck is EIP712{

    string private constant SIGNING_DOMAIN = "Yeti";
    string private constant SIGNATURE_VERSION = "1";

    struct Rarity{
        uint tokenId;
        uint rarityIndex;
        bytes signature;
    }

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){}

    function getSigner(Rarity memory rarity) internal view returns(address){
        return _verify(rarity);
    }

    /// @notice Returns a hash of the given rarity, prepared using EIP712 typed data hashing rules.
  
    function _hash(Rarity memory rarity) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("Rarity(uint256 tokenId,uint256 rarityIndex)"),
      rarity.tokenId,
      rarity.rarityIndex
    )));
    }

    function _verify(Rarity memory rarity) internal view returns (address) {
        bytes32 digest = _hash(rarity);
        return ECDSA.recover(digest, rarity.signature);
    }

}