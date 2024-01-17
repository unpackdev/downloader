// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./ReswapPairERC20.sol";
import "./ReswapPairMissingEnumerable.sol";
import "./IReswapPairFactoryLike.sol";

contract ReswapPairMissingEnumerableERC20 is
    ReswapPairMissingEnumerable,
    ReswapPairERC20
{
    function pairVariant()
        public
        pure
        override
        returns (IReswapPairFactoryLike.PairVariant)
    {
        return IReswapPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ERC20;
    }
}
