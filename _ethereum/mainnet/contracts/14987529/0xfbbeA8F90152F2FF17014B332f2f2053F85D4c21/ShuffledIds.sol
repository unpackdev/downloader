// SPDX-License-Identifier: AGPLv3

pragma solidity ^0.8.10;

library ShuffledIds {
    struct Shuffler {
        uint256 remaining;
        uint256 offset;
        uint256 nonce;
        mapping(uint256 => uint256) swapMap;
        bool initialized;
    }

    modifier ifNotEmpty(Shuffler storage s) {
        require(s.remaining > 0, "No more ids left");
        _;
    }

    modifier ifInitialized(Shuffler storage s) {
        require(s.initialized == true, "Shuffler not initialized yet");
        _;
    }

    function initialize(
        Shuffler storage s,
        uint256 minIds,
        uint256 maxIds
    ) internal {
        require(minIds < maxIds && minIds > 0, "invalid lower bound");
        s.remaining = maxIds - minIds + 1;
        s.offset = minIds - 1;
        s.initialized = true;
    }

    function decrement(Shuffler storage s) internal ifInitialized(s) {
        uint256 value = s.remaining;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            s.remaining = value - 1;
        }
    }

    function swap(Shuffler storage s, uint256 index) internal ifInitialized(s) {
        decrement(s);

        if (s.swapMap[s.remaining] == 0) {
            s.swapMap[index] = s.remaining;
        } else {
            s.swapMap[index] = s.swapMap[s.remaining];
        }
    }

    function pop(Shuffler storage s, uint256 randomnumber)
        internal
        ifInitialized(s)
        returns (uint256)
    {
        uint256 temp = s.swapMap[randomnumber];

        if (temp == 0) {
            swap(s, randomnumber);
            return randomnumber + s.offset + 1;
        } else {
            swap(s, randomnumber);
            return temp + s.offset + 1;
        }
    }

    function popRandomId(Shuffler storage s)
        internal
        ifNotEmpty(s)
        ifInitialized(s)
        returns (uint256)
    {
        uint256 randomnumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    msg.sender,
                    blockhash(block.number - 1),
                    s.nonce
                )
            )
        ) % s.remaining;

        s.nonce++;

        return pop(s, randomnumber);
    }

    function getRemaining(Shuffler storage s)
        internal
        view
        ifInitialized(s)
        returns (uint256)
    {
        return s.remaining;
    }
}
