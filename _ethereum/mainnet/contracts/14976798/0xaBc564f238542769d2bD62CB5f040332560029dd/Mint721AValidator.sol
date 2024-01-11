// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-EIP712.sol";
import "./ECDSA.sol";

contract Mint721AValidator is EIP712 {
    constructor(string memory name, string memory version)
        EIP712(name, version)
    {}

    function validate(
        address signer,
        bytes32 structHash,
        bytes memory signature
    ) internal view {
        bytes32 encodedHash = _hashTypedDataV4(structHash);
        require(
            ECDSA.recover(encodedHash, signature) == signer,
            "RC: signature verification error"
        );
    }
}
