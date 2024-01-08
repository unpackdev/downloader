// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HyperRandom {
    struct Random {
        uint256 lastRandom;
    }

    function generate(Random storage _r, uint256 _nonce) internal returns (uint256) {
        unchecked {
            _r.lastRandom = uint256(
                keccak256(
                    abi.encode(
                        keccak256(
                            abi.encodePacked(
                                msg.sender,
                                tx.origin,
                                gasleft(),
                                _r.lastRandom,
                                block.timestamp,
                                block.number,
                                blockhash(block.number),
                                blockhash(block.number - 100),
                                _nonce
                            )
                        )
                    )
                )
            );
        }

        return _r.lastRandom;
    }
}
