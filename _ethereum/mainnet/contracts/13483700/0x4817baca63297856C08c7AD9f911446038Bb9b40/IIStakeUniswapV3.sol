//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IIStakeUniswapV3 {

    /// @dev stake tokenId of UniswapV3
    /// @param tokenId  tokenId
    /// @param deadline the deadline that valid the owner's signature
    /// @param v the owner's signature - v
    /// @param r the owner's signature - r
    /// @param s the owner's signature - s
    function stakePermit(
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @dev stake tokenId of UniswapV3
    /// @param tokenId  tokenId
    function stake(uint256 tokenId) external;

    /// @dev view mining information of tokenId
    /// @param tokenId  tokenId
    function getMiningTokenId(uint256 tokenId)
        external
        returns (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            uint160 secondsInside,
            uint256 secondsInsideDiff256,
            uint256 liquidity,
            uint256 balanceOfTokenIdRay,
            uint256 minableAmountRay,
            uint256 secondsInside256,
            uint256 secondsAbsolute256
        );


}
