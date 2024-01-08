//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeUniswapV3 {
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

    /// @dev withdraw the deposited token.
    ///      The amount mined with the deposited liquidity is claimed and taken.
    ///      The amount of mining taken is changed in proportion to the amount of time liquidity
    ///      has been provided since recent mining
    /// @param tokenId  tokenId
    function withdraw(uint256 tokenId) external;

    /// @dev The amount mined with the deposited liquidity is claimed and taken.
    ///      The amount of mining taken is changed in proportion to the amount of time liquidity
    ///       has been provided since recent mining
    /// @param tokenId  tokenId
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
    /// @return args liquidity,  startTime, claimedTime, startBlock, claimedBlock, claimedAmount
    /// @return secondsPL secondsPerLiquidityInsideInitialX128, secondsPerLiquidityInsideX128Las
    function getDepositToken(uint256 tokenId)
        external
        view
        returns (
            address poolAddress,
            int24[2] memory tick,
            uint128 liquidity,
            uint256[5] memory args,
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

    /*
    /// @dev pool's infos
    /// @return factory  pool's factory address
    /// @return token0  token0 address
    /// @return token1  token1 address
    /// @return fee  fee
    /// @return tickSpacing  tickSpacing
    /// @return maxLiquidityPerTick  maxLiquidityPerTick
    /// @return liquidity  pool's liquidity
    function poolInfos()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing,
            uint128 maxLiquidityPerTick,
            uint128 liquidity
        );

    /// @dev key's info
    /// @param key hash(owner, tickLower, tickUpper)
    /// @return _liquidity  key's liquidity
    /// @return feeGrowthInside0LastX128  key's feeGrowthInside0LastX128
    /// @return feeGrowthInside1LastX128  key's feeGrowthInside1LastX128
    /// @return tokensOwed0  key's tokensOwed0
    /// @return tokensOwed1  key's tokensOwed1
    function poolPositions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    */

    /// @dev pool's slot0 (current position)
    /// @return sqrtPriceX96  The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick  The current tick of the pool
    /// @return observationIndex  The index of the last oracle observation that was written,
    /// @return observationCardinality  The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext  The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol  The protocol fee for both tokens of the pool
    /// @return unlocked  Whether the pool is currently locked to reentrancy
    function poolSlot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /*
    /// @dev _tokenId's position
    /// @param _tokenId  tokenId
    /// @return nonce  the nonce for permits
    /// @return operator  the address that is approved for spending this token
    /// @return token0  The address of the token0 for pool
    /// @return token1  The address of the token1 for pool
    /// @return fee  The fee associated with the pool
    /// @return tickLower  The lower end of the tick range for the position
    /// @return tickUpper  The higher end of the tick range for the position
    /// @return liquidity  The liquidity of the position
    /// @return feeGrowthInside0LastX128  The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128  The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0  The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1  The uncollected amount of token1 owed to the position as of the last computation
    function npmPositions(uint256 _tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @dev snapshotCumulativesInside
    /// @param tickLower  The lower tick of the range
    /// @param tickUpper  The upper tick of the range
    /// @return tickCumulativeInside  The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128  The snapshot of seconds per liquidity for the range
    /// @return secondsInside  The snapshot of seconds per liquidity for the range
    /// @return curTimestamps  current Timestamps
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside,
            uint32 curTimestamps
        );
    */
    /// @dev mining end time
    /// @return endTime mining end time
    function miningEndTime() external view returns (uint256 endTime);

    /// @dev get price
    /// @param decimals pool's token1's decimals (ex. 1e18)
    /// @return price price
    function getPrice(uint256 decimals) external view returns (uint256 price);

    /// @dev Liquidity provision time (seconds) at a specific point in time since the token was recently mined
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.) set it to the current time.
    /// @return secondsAbsolute Absolute duration (in seconds) from the latest mining to the time of expectTime
    /// @return secondsInsideDiff256 The time (in seconds) that the token ID provided liquidity from the last claim (or staking time) to the present time.
    /// @return expectTime time used in the calculation
    function currentliquidityTokenId(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        external
        view
        returns (
            uint256 secondsAbsolute,
            uint256 secondsInsideDiff256,
            uint256 expectTime
        );

    /// @dev Coinage balance information that tokens can receive in the future
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.)
    /// @return currentTotalCoinage Current Coinage Total Balance
    /// @return afterTotalCoinage Total balance of Coinage at a future point in time
    /// @return afterBalanceTokenId The total balance of the coin age of the token at a future time
    /// @return expectTime future time
    /// @return addIntervalTime Duration (in seconds) between the future time and the recent mining time
    function currentCoinageBalanceTokenId(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        external
        view
        returns (
            uint256 currentTotalCoinage,
            uint256 afterTotalCoinage,
            uint256 afterBalanceTokenId,
            uint256 expectTime,
            uint256 addIntervalTime
        );

    /// @dev Estimated additional claimable amount on a specific time
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.)
    /// @return miningAmount Amount you can claim
    /// @return nonMiningAmount The amount that burn without receiving a claim
    /// @return minableAmount Total amount of mining allocated at the time of claim
    /// @return minableAmountRay Total amount of mining allocated at the time of claim (ray unit)
    /// @return expectTime time used in the calculation
    function expectedPlusClaimableAmount(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        external
        view
        returns (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            uint256 minableAmountRay,
            uint256 expectTime
        );
}
