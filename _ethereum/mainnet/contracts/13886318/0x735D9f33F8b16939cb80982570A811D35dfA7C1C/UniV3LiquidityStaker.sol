// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./EnumerableSet.sol";

import "./GovIdentity.sol";
import "./IUniswapV3Staker.sol";

import "./ERC20Extends.sol";
import "./UniV3PMExtends.sol";

pragma abicoder v2;
/// @title Position Management and Staker tokenId
/// @notice Provide asset operation functions, allow authorized identities to perform asset operations, and achieve the purpose of increasing the net value of the fund
contract UniV3LiquidityStaker is GovIdentity {

    using EnumerableSet for EnumerableSet.UintSet;

    //Uni V3 Staker
    address constant public staker = address(0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d);
    //Working positions
    EnumerableSet.UintSet internal stakers;

    //Staker tokenId
    event Staker(uint256 tokenId);
    //UnStaker tokenId
    event UnStaker(uint256 tokenId);

    /// @notice check stakers contains tokenId
    /// @dev contains
    /// @return contains
    function checkStakers(uint256 tokenId) public view returns (bool){
        return stakers.contains(tokenId);
    }

    /// @notice in stakers tokenId array
    /// @dev read in stakers NFT array
    /// @return tokenIds NFT array
    function stakersPos() public view returns (uint256[] memory tokenIds){
        uint256 length = stakers.length();
        tokenIds = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = stakers.at(i);
        }
    }

    /// @notice callback function when receiving NFT
    /// @dev only Univ3 NFT transfer in is allowed
    /// @return default value
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external returns (bytes4){
        require(
            msg.sender == address(UniV3PMExtends.PM),
            'not a univ3 nft'
        );
        if (stakers.contains(tokenId)) {
            stakers.remove(tokenId);
            emit UnStaker(tokenId);
        }
        return this.onERC721Received.selector;
    }


    /// @notice Authorize UniV3 contract to move fund asset
    /// @dev Only allow governance and strategist identities to execute authorized functions to reduce miner fee consumption
    /// @param token Authorized target token
    function safeApproveStaker(address token) public onlyStrategistOrGovernance {
        ERC20Extends.safeApprove(token, staker, type(uint256).max);
    }

    /// @notice buildIncentiveKey IncentiveKey
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    function buildIncentiveKey(
        address rewardToken,
        address pool,
        uint256 startTime,
        uint256 endTime
    ) internal view returns (IUniswapV3Staker.IncentiveKey memory){
        return IUniswapV3Staker.IncentiveKey({
        rewardToken : rewardToken,
        pool : pool,
        startTime : startTime,
        endTime : endTime,
        refundee : address(this)
        });
    }

    /// @notice staker tokenID
    /// @dev Only the governance and strategist identities are allowed to execute stakerNFT function calls,
    /// @param tokenId NFT id
    function stakerNFT(uint256 tokenId) external onlyStrategistOrGovernance {
        INonfungiblePositionManager pm = UniV3PMExtends.PM;
        pm.safeTransferFrom(address(this), staker, tokenId);
        stakers.add(tokenId);
        emit Staker(tokenId);
    }

    /// @notice Creates a new liquidity mining incentive program
    /// @dev Only the governance identities are allowed to execute createIncentive function calls,
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param reward The amount of reward tokens to be distributed
    function createIncentive(
        address rewardToken,
        address pool,
        uint256 startTime,
        uint256 endTime,
        uint256 reward
    ) external onlyGovernance {
        IUniswapV3Staker.IncentiveKey memory key = buildIncentiveKey(rewardToken, pool, startTime, endTime);
        IUniswapV3Staker(staker).createIncentive(key, reward);
    }

    /// @notice Ends an incentive after the incentive end time has passed and all stakes have been withdrawn
    /// @dev Only the governance identities are allowed to execute createIncentive function calls,
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    function endIncentive(
        address rewardToken,
        address pool,
        uint256 startTime,
        uint256 endTime
    ) external onlyGovernance {
        IUniswapV3Staker.IncentiveKey memory key = buildIncentiveKey(rewardToken, pool, startTime, endTime);
        IUniswapV3Staker(staker).endIncentive(key);
    }

    /// @notice stakeToken staker tokenID
    /// @dev Only the governance and strategist identities are allowed to execute stakeToken function calls,
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param tokenId The ID of the token to stake
    function stakeToken(
        address rewardToken,
        address pool,
        uint256 startTime,
        uint256 endTime,
        uint256 tokenId
    ) external onlyStrategistOrGovernance {
        IUniswapV3Staker.IncentiveKey memory key = buildIncentiveKey(rewardToken, pool, startTime, endTime);
        IUniswapV3Staker(staker).stakeToken(key, tokenId);
    }

    /// @notice unStakeToken staker tokenID
    /// @dev Only the governance and strategist identities are allowed to execute unStakeToken function calls,
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param tokenId The ID of the token to stake
    function unStakeToken(
        address rewardToken,
        address pool,
        uint256 startTime,
        uint256 endTime,
        uint256 tokenId
    ) external onlyStrategistOrGovernance {
        IUniswapV3Staker.IncentiveKey memory key = buildIncentiveKey(rewardToken, pool, startTime, endTime);
        IUniswapV3Staker(staker).unstakeToken(key, tokenId);
    }

    // @notice claimReward staker reward
    /// @dev Only the governance and strategist identities are allowed to execute claimReward function calls,
    /// @param rewardToken The token being distributed as a reward
    function claimReward(
        address rewardToken
    ) external onlyStrategistOrGovernance {
        uint256 reward = IUniswapV3Staker(staker).rewards(rewardToken, address(this));
        IUniswapV3Staker(staker).claimReward(rewardToken, address(this), reward);
    }

    // @notice withdrawToken staker tokenId
    /// @dev Only the governance and strategist identities are allowed to execute unStakeToken function calls,
    /// @param tokenId The unique identifier of an Uniswap V3 LP token
    /// @param data An optional data array that will be passed along to the `to` address via the NFT safeTransferFrom
    function withdrawToken(
        uint256 tokenId,
        bytes memory data
    ) external onlyStrategistOrGovernance {
        IUniswapV3Staker(staker).withdrawToken(tokenId, address(this), data);
    }
}
