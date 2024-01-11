// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IUniswapV3Pool.sol";
import "./IEjectResolver.sol";
import "./IEjectLP.sol";
import "./SEject.sol";
import "./FEjectLp.sol";
import "./CEjectLP.sol";

contract RangeOrderResolver is IEjectResolver {
    IEjectLP public immutable ejectLP;

    constructor(IEjectLP ejectLP_) {
        ejectLP = ejectLP_;
    }

    // solhint-disable-next-line function-max-lines
    function checker(
        uint256 tokenId_,
        Order memory order_,
        address feeToken_
    ) external view override returns (bool, bytes memory data) {
        if (
            feeToken_ != ETH ||
            ejectLP.hashById(tokenId_) != keccak256(abi.encode(order_))
        ) return (false, "");

        (bool isExpired, ) = ejectLP.isExpired(order_);
        if (isExpired)
            return (
                true,
                abi.encodeWithSelector(
                    IEjectLP.ejectOrSettle.selector,
                    tokenId_,
                    order_,
                    false
                )
            );

        (
            ,
            ,
            address token0,
            address token1,
            uint24 feeTier,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = ejectLP.nftPositionManager().positions(tokenId_);
        IUniswapV3Pool pool = _pool(ejectLP.factory(), token0, token1, feeTier);
        (bool isEjectable, ) = ejectLP.isEjectable(tokenId_, order_, pool);
        if (isEjectable)
            return (
                true,
                abi.encodeWithSelector(
                    IEjectLP.ejectOrSettle.selector,
                    tokenId_,
                    order_,
                    true
                )
            );

        return (false, "");
    }
}
