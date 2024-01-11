// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

// whitelist check
abstract contract Whitelist is Ownable, EIP712 {

    using ECDSA for bytes32;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant WHITELIST_TYPEHASH =  keccak256("Whitelist(address buyer)");

    // the whitelist signer account
    address public whitelistSigner;

    constructor(string memory name, string memory version)
        EIP712(name, version)
    {
        DOMAIN_SEPARATOR = keccak256(
                    abi.encode(
                        keccak256(
                            "EIP712Domain(string name,address verifyingContract)"
                        ),
                        keccak256(bytes("WL")),
                        address(this)
                    )
                );
    }

    // need sender is in whitelist
    modifier isSenderWhitelisted(
        bytes memory _signature
    ) {
        require(
            getSigner(_signature) == whitelistSigner,
            "Whitelist: Invalid signature"
        );
        _;
    } 

    // set whitelist signer
    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    // get whitelist signer
    function getSigner(bytes memory signature) public view returns (address)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender))
            )
        );
        return digest.recover(signature);
    }
 
}
