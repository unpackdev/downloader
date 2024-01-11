//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./draft-EIP712Upgradeable.sol";

contract ParallabsMintPassSigner is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "ParallabsMintPass";
    string private constant SIGNATURE_VERSION = "1";

    struct listed {
        address addr;
        bool inSilverList;
        bool inGoldList;
        bytes signature;
    }
    
    function __ParallabsMintPassSigner_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }
    
    function getSigner(listed memory _buyer) public view returns (address) {
        return _verify(_buyer);
    }

    function _hash(listed memory _buyer) internal view returns (bytes32){
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "listed(address addr,bool inSilverList,bool inGoldList)"
                    ),
                    _buyer.addr,
                    _buyer.inSilverList,
                    _buyer.inGoldList
                )
            )
        );
    }

    function _verify(listed memory _buyer) internal view returns (address) {
        bytes32 digest = _hash(_buyer);
        return ECDSAUpgradeable.recover(digest, _buyer.signature);
    }
}
