//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeUniswapV3 {
    /// @dev Stake amount
    /// @param tokenId  uniswapV3 LP Token
    /// @param deadline  the deadline that valid the owner's signature
    /// @param v the owner's signature - v
    /// @param r the owner's signature - r
    /// @param s the owner's signature - s
    function stake(
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getClaimLiquidity(uint256 tokenId)
        external
        returns (
            uint256 realReward,
            uint256 unableClaimReward,
            uint160 secondsPerLiquidityInsideX128,
            uint256 balanceCoinageOfUser,
            uint256 _coinageReward
        );

    /// @dev withdraw
    function withdraw(uint256 tokenId) external;

    /// @dev Claim for reward
    function claim(uint256 tokenId) external;

    // function setPool(
    //     address token0,
    //     address token1,
    //     string calldata defiInfoName
    // ) external;

    /// @dev
    function getUserStakedTokenIds(address user)
        external
        view
        returns (uint256[] memory ids);

    /// @dev tokenId's deposited information
    /// @param tokenId   tokenId
    /// @return poolAddress   poolAddress
    /// @return tick tick,
    /// @return liquidity liquidity,
    /// @return args liquidity,  startTime, endTime, claimedTime, startBlock, claimedBlock, claimedAmount
    /// @return secondsPL secondsPerLiquidityInsideInitialX128, secondsPerLiquidityInsideX128Las
    function getDepositToken(uint256 tokenId)
        external
        view
        returns (
            address poolAddress,
            int24[2] memory tick,
            uint128 liquidity,
            uint256[6] memory args,
            uint160[2] memory secondsPL
        );

    function getUserStakedTotal(address user)
        external
        view
        returns (
            uint256 totalDepositAmount,
            uint256 totalClaimedAmount,
            uint256 totalUnableClaimAmount
        );

    /// @dev Give the infomation of this stakeContracts
    /// @return return1  [token, vault, stakeRegistry, coinage]
    /// @return return2  [poolToken0, poolToken1, nonfungiblePositionManager, uniswapV3FactoryAddress]
    /// @return return3  [totalStakers, totalStakedAmount, rewardClaimedTotal,rewardNonLiquidityClaimTotal]
    function infos()
        external
        view
        returns (
            address[4] memory,
            address[4] memory,
            uint256[4] memory
        );
}
