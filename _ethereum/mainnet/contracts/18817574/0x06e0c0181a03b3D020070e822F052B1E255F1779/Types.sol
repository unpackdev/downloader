// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Types {
    // keccak256("Claim(bool isBurning,address instance,address recipient,address collection,uint256[] tokenIds)")
    bytes32 internal constant CLAIM_HASH = 0x4d0fc8478dfac92cdaec10927689f2e24230be993b5749e0ca853c8e3c2243d3;

    struct CloneInfo {
        address instance;
        address creator;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Claim {
        bool isBurning;
        address instance;
        address recipient;
        address collection;
        uint256[] tokenIds;
    }

    function hash(Claim memory claim) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIM_HASH,
                    claim.isBurning,
                    address(this),
                    claim.recipient,
                    claim.collection,
                    keccak256(abi.encodePacked(claim.tokenIds))
                )
            );
    }
}
