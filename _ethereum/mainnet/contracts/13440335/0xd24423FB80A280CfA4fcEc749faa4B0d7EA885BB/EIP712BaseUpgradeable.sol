//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Initializable.sol";

contract EIP712BaseUpgradeable is Initializable {

    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)");

    bytes32 internal domainSeparator;

    function __EIP712Base_init_unchained(string memory name, string memory version) internal initializer {
        domainSeparator = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            address(this),
            bytes32(getChainId())
        ));
    }

    function getChainId() public pure returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() public view returns(bytes32) {
        return domainSeparator;
    }

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }

    uint256[49] private __gap;
}
