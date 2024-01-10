// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract EIP712Library {
    string public constant name = 'Plasma Gas Station';
    string public constant version = '1';
    mapping(address => uint256) public nonces;

    bytes32 immutable public DOMAIN_SEPARATOR;

    bytes32 immutable public TX_REQUEST_TYPEHASH;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );

        TX_REQUEST_TYPEHASH = keccak256("TxRequest(address from,address to,uint256 gas,uint256 nonce,uint256 deadline,bytes data)");
    }

    function getNonce(address from) external view returns (uint256) {
        return nonces[from];
    }

    function _getSigner(address from, address to, uint256 gas, uint256 nonce, bytes calldata data, uint256 deadline, bytes calldata sign) internal view returns (address) {
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encodePacked(
                    TX_REQUEST_TYPEHASH,
                    uint256(uint160(from)),
                    uint256(uint160(to)),
                    gas,
                    nonce,
                    deadline,
                    keccak256(data)
                ))
            ));

        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sign);
        return ecrecover(digest, v, r, s);
    }

    function _splitSignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65, "Signature invalid length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature invalid v byte");
    }
}
