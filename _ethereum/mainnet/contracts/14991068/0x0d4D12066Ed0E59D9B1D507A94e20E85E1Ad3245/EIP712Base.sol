// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";
    bytes32 constant internal _EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)")
    );

    bool internal _inited = false;
    bytes32 internal _domainSeperator;

    function _initializeEIP712(string memory name) internal {
        require(!_inited, "already inited");
        _inited = true;
        _domainSeperator = keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function getDomainSeperator() public view returns (bytes32) {
        return _domainSeperator;
    }

    // https://eips.ethereum.org/EIPS/eip-712
    // "\\x19" makes the encoding deterministic
    // "\\x01" is the version byte to make it compatible to EIP-191
    function _toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
        );
    }
}
