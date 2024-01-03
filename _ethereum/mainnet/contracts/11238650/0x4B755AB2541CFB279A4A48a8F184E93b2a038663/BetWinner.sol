pragma solidity ^0.6.9;

import "./BetDataStructure.sol";




contract BetWinner is BetDataStructure {
}

library UIntArrayUtils {
    function merge (uint32[] memory a, uint32[] memory b)
        internal
        pure
        returns (uint32[] memory)
    {
        uint32[] memory res = new uint32[](a.length);
        for (uint32 i = 0; i < a.length; i++) {
            res[i] = a[i] + b[i];
        }
        return res;
    }

    function reduce (uint[] memory a, function(uint, uint) pure returns (uint) f)
        internal
        pure
        returns (uint)
    {
        uint r = a[0];
        for (uint i = 1; i < a.length; i++) {
            r = f(r, a[i]);
        }
        return r;
    }
}