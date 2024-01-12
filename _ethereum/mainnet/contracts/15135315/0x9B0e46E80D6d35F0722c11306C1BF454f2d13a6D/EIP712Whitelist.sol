// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ECDSA.sol";
import "./draft-EIP712.sol";


contract EIP712Whitelist is EIP712{
    address private constant SIGNER_ADDRESS= 0x2e2C7099da471f09886e7425D0C1073ed34EB4Ce;

    constructor()  EIP712("CHEWYHK","1"){}
    
    /**
        @notice verify signature for privateMint
    */
    function simpleVerify(bytes memory signature) public view returns (bool) {
        //hash the plain text message
        bytes32 hashStruct = keccak256(abi.encode(           
            keccak256("TicketSigner(address signer)"),
                SIGNER_ADDRESS
        ));
        bytes32 digest = _hashTypedDataV4(hashStruct);

        // verify typed signature
        address signer = ECDSA.recover(digest, signature);
        bool isSigner = signer == SIGNER_ADDRESS;
        return isSigner;
    }

}