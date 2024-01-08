// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library RandomLib {
    struct Random {
        uint256 lastRandom;
        uint256 initialRandom;
    }

    function nextRandom(Random storage g) internal returns (uint256) {
        unchecked {
            g.lastRandom = uint256(
                keccak256(
                    abi.encode(
                        keccak256(
                            abi.encodePacked(
                                msg.sender,
                                tx.origin,
                                gasleft(),
                                g.lastRandom,
                                g.initialRandom,
                                block.timestamp,
                                block.number,
                                blockhash(block.number),
                                blockhash(block.number - 100)
                            )
                        )
                    )
                )
            );
        }
        return g.lastRandom;
    }

    /// @dev set by the randomness from chainlink
    function setInitialRandom(Random storage g, uint256 initialRandom)
        internal
    {
        g.initialRandom = initialRandom;
    }
}
