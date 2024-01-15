// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./LSSVMPairETH.sol";
import "./LSSVMPairMissingEnumerable.sol";
import "./ILSSVMPairFactoryLike.sol";

contract LSSVMPairMissingEnumerableETH is
    LSSVMPairMissingEnumerable,
    LSSVMPairETH
{
    function pairVariant()
        public
        pure
        override
        returns (ILSSVMPairFactoryLike.PairVariant)
    {
        return ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH;
    }
}
