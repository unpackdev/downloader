//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./draft-EIP712Upgradeable.sol";

contract YetiSigner is EIP712Upgradeable{

    ///@dev SIGNING_DOMAIN = "Yeti-Migration" ; SIGNATURE_VERSION = "1"
    string private  SIGNING_DOMAIN;
    string private  SIGNATURE_VERSION;

    struct Rarity{
        address userAddress;
        uint tokenId;
        uint level;
        uint exp;
        uint rarity;
        uint pass;
        bytes signature;
    }

    function __YetiSigner_init(string memory domain, string memory version) internal initializer {
        SIGNING_DOMAIN = domain;
        SIGNATURE_VERSION = version;
        __EIP712_init(domain, version);
    }

    function getSigner(Rarity memory rarity) public view returns(address){
        return _verify(rarity);
    }

    function _hash(Rarity memory rarity) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
                keccak256("Rarity(address userAddress,uint256 tokenId,uint256 level,uint256 exp,uint256 rarity,uint256 pass)"),
                rarity.userAddress,
                rarity.tokenId,
                rarity.level,
                rarity.exp,
                rarity.rarity,
                rarity.pass
            )));
    }

    function _verify(Rarity memory rarity) internal view returns (address) {
        bytes32 digest = _hash(rarity);
        return ECDSAUpgradeable.recover(digest, rarity.signature);
    }

}