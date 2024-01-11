// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Ownable.sol";

contract EIP712Whitelisting is Ownable {
    using ECDSA for bytes32;

    address whitelistSigningKey = address(0);

    bytes32 public DOMAIN_SEPARATOR;

    // 0x1c2b8a7f8e96191b2a87187d671b4673d314e3a6965fc91f499c66051061f118
    bytes32 public constant MINT_TYPEHASH =
        keccak256("mint(address to,uint256 amount,uint256 nonce)");

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("WhitelistToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function setWhitelistSigningAddress(address _signAddress) public onlyOwner {
        whitelistSigningKey = _signAddress;
    }

    function isEIP712WhiteListed(
        bytes calldata signature,
        uint256 amount,
        uint256 numberMinted
    ) public view returns (bool) {
        require(whitelistSigningKey != address(0), "whitelist not enabled.");
        return
            getEIP712RecoverAddress(signature, amount, numberMinted) ==
            whitelistSigningKey;
    }

    function getEIP712RecoverAddress(
        bytes calldata signature,
        uint256 amount,
        uint256 numberMinted
    ) internal view returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(MINT_TYPEHASH, msg.sender, amount, numberMinted)
                )
            )
        );
        return digest.recover(signature);
    }
}
