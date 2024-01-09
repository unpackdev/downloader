// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";



// Move the last element to the deleted spot.
// Remove the last element.
function _burn(uint256[] storage array, uint32 index) {
    require(index < array.length);
    array[index] = array[array.length - 1];
    array.pop();
}

library Bits {
    uint256 internal constant ONE = uint256(1);

    // uint8 constant internal ONES = uint8(~0);

    // Sets the bit at the given 'index' in 'self' to '1'.
    // Returns the modified value.
    function setBit(uint256 self, uint8 index) internal pure returns (uint256) {
        return self | (ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to '0'.
    // Returns the modified value.
    function clearBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self & ~(ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to:
    //  '1' - if the bit is '0'
    //  '0' - if the bit is '1'
    // Returns the modified value.
    function toggleBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self ^ (ONE << index);
    }

    // Get the value of the bit at the given 'index' in 'self'.
    function bit(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8((self >> index) & 1);
    }

    // Check if the bit at the given 'index' in 'self' is set.
    // Returns:
    //  'true' - if the value of the bit is '1'
    //  'false' - if the value of the bit is '0'
    function bitSet(uint256 self, uint8 index) internal pure returns (bool) {
        return (self >> index) & 1 == 1;
    }

    // Checks if the bit at the given 'index' in 'self' is equal to the corresponding
    // bit in 'other'.
    // Returns:
    //  'true' - if both bits are '0' or both bits are '1'
    //  'false' - otherwise
    function bitEqual(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (bool) {
        return ((self ^ other) >> index) & 1 == 0;
    }

    // Get the bitwise NOT of the bit at the given 'index' in 'self'.
    function bitNot(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8(1 - ((self >> index) & 1));
    }

    // Computes the bitwise AND of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitAnd(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self & other) >> index) & 1);
    }

    // Computes the bitwise OR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitOr(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self | other) >> index) & 1);
    }

    // Computes the bitwise XOR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitXor(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self ^ other) >> index) & 1);
    }

    // Gets 'numBits' consecutive bits from 'self', starting from the bit at 'startIndex'.
    // Returns the bits as a 'uint'.
    // Requires that:
    //  - '0 < numBits <= 256'
    //  - 'startIndex < 256'
    //  - 'numBits + startIndex <= 256'
    // function bits(uint self, uint8 startIndex, uint16 numBits) internal pure returns (uint) {
    //     require(0 < numBits && startIndex < 256 && startIndex + numBits <= 256);
    //     return self >> startIndex & ONES >> 256 - numBits;
    // }

    // Computes the index of the highest bit set in 'self'.
    // Returns the highest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function highestBitSet(uint256 self) internal pure returns (uint8 highest) {
        require(self != 0);
        uint256 val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & (((ONE << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }
    }

    // Computes the index of the lowest bit set in 'self'.
    // Returns the lowest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function lowestBitSet(uint256 self) internal pure returns (uint8 lowest) {
        require(self != 0);
        uint256 val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & ((ONE << i) - 1) == 0) {
                lowest += i;
                val >>= i;
            }
        }
    }
}

contract IEnvelope is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    address private signer_;

    struct Status {
        bool initialized;
        bool claimed;
    }

    struct Envelope {
        uint256 balance;
        uint256 minPerOpen;
        address creator;
        mapping(uint256 => Status) passwords;
        uint16 numParticipants;
        uint8 passLength;
        uint timestamp;
    }

    struct MerkleEnvelope {
        uint256 balance;
        uint256 minPerOpen;
        // we need a Merkle roots, to
        // keep track of claimed passwords,
        bytes32 unclaimedPasswords;
        // we will keep a bitset for used passwords
        uint8[] isPasswordClaimed;
        address creator;
        uint16 numParticipants;
    }

    struct MerkleEnvelopeERC721 {
        // we need a Merkle roots, to
        // keep track of claimed passwords,
        bytes32 unclaimedPasswords;
        // we will keep a bitset for used passwords
        uint8[] isPasswordClaimed;
        address creator;
        uint16 numParticipants;
        address tokenAddress;
        uint256[] tokenIDs;
    }

    function setSigner(address signer) public onlyOwner {
        signer_ = signer;
    }

    function recover(bytes calldata signature, string calldata unhashedPassword)
        internal  
        view  
        returns (bool)
    {
        address addr = keccak256(abi.encode(msg.sender, unhashedPassword)).toEthSignedMessageHash().recover(signature);
        return (addr == signer_);
    }

    function recover(bytes calldata signature, bytes32 leaf)
        internal  
        view  
        returns (bool)
    {
        address addr = keccak256(abi.encode(msg.sender, leaf)).toEthSignedMessageHash().recover(signature);
        return (addr == signer_);
    }

    function initStatus() internal pure returns (Status memory) {
        Status memory envStatus;
        envStatus.initialized = true;
        envStatus.claimed = false;
        return envStatus;
    }

    function hashPassword(string memory unhashedPassword)
        public
        pure
        returns (uint64)
    {
        uint64 MAX_INT = 2**64 - 1;
        uint256 password = uint256(
            keccak256(abi.encodePacked(unhashedPassword))
        );
        uint64 passInt64 = uint64(password % MAX_INT);
        return passInt64;
    }

    function validateMinPerOpen(
        uint256 envBalance,
        uint256 minPerOpen,
        uint16 numParticipants
    ) internal pure {
        require(
            envBalance >= minPerOpen * numParticipants,
            "Everyone should be able to get min!"
        );
    }

    function getMoneyThisOpen(
        address receiver,
        uint256 envBalance,
        uint256 minPerOpen,
        uint16 numParticipants
    ) public view returns (uint256) {
        // calculate the money open amount. We calculate a rand < 1k, then
        // max * rand1k / 1k
        // we generate a psuedorandom number. The cast here is basicalluy the same as mod
        // https://ethereum.stackexchange.com/questions/100029/how-is-uint8-calculated-from-a-uint256-conversion-in-solidity
        uint16 rand = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        receiver
                    )
                )
            )
        );
        uint16 rand1K = rand % 1000;
        uint256 randBalance = envBalance - minPerOpen * numParticipants;
        // We need to be careful with overflow here if the balance is huge. It needs to be 1k less than max.
        uint256 maxThisOpen = randBalance / 2;
        uint256 moneyThisOpen = ((maxThisOpen * rand1K) / 1000) + minPerOpen;
        return moneyThisOpen;
    }
}
