// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Traits {
    uint256 constant NUM_SAMPLING = 8;
    uint256 constant SAMPLING_BITS = 8;
    uint256 constant SAMPLING_MASK = (1 << SAMPLING_BITS) - 1;

    


    function gaussianTrait(uint256 seed) internal pure returns(uint256 trait) {
        unchecked{
            for(uint256 i=0; i < NUM_SAMPLING; i++){
                trait += (seed >> (i * SAMPLING_BITS)) & SAMPLING_MASK; 
            }
        }
    }

    function strength(uint256 seed, uint256 level) internal pure returns(uint256) {
        return level * gaussianTrait(seed);
    }

    function house(uint256 seed) internal pure returns(uint256) {
        return uint256(keccak256(abi.encode(
            seed,
            keccak256("house")
             )))% 4;
    }

    
}
