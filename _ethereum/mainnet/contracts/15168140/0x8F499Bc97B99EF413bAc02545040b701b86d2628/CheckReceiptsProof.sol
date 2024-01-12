// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./CommonStructs.sol";


// check readme for focs
function calcReceiptsHash(bytes[] calldata proof, bytes32 el, uint proofStart) pure returns (bytes32) {
    bytes memory s;

    for (uint i = proofStart; i < proof.length; i += 2) {
        s = abi.encodePacked(proof[i], el, proof[i + 1]);
        el = (s.length > 32) ? keccak256(s) : bytes32(s);
    }

    return el;
}


function calcTransferReceiptsHash(CommonStructs.TransferProof calldata p, address eventContractAddress) pure returns (bytes32) {
    bytes32 el = keccak256(abi.encodePacked(
            p.receiptProof[0],
            eventContractAddress,
            p.receiptProof[1],
            toBinary(p.eventId),
            p.receiptProof[2],
            abi.encode(p.transfers),
            p.receiptProof[3]
        ));
    return calcReceiptsHash(p.receiptProof, el, 4);
    // start from proof[4]
}


function toBinary(uint _x) pure returns (bytes memory) {
    bytes memory b = new bytes(32);
    assembly {
        mstore(add(b, 32), _x)
    }
    uint i;
    for (i = 0; i < 32; i++) {
        if (b[i] != 0) {
            break;
        }
    }
    bytes memory res = new bytes(32 - i);
    for (uint j = 0; j < res.length; j++) {
        res[j] = b[i++];
    }
    return res;
}
