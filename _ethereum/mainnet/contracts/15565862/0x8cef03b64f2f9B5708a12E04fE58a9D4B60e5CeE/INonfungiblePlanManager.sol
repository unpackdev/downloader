// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PoolAddress.sol";

interface INonfungiblePlanManager {
    event PlanMinted(
        uint256 tokenId,
        address owner,
        address token0,
        address token1,
        uint8 frequency,
        uint256 planIndex,
        address investor
    );
    struct Plan {
        uint96 nonce;
        address operator;
        address investor;
        address token0;
        address token1;
        uint8 frequency;
        uint256 index;
        uint256 tickAmount;
        uint256 createdTime;
    }
    struct PlanStatistics {
        uint256 swapAmount1;
        uint256 withdrawnAmount1;
        uint256 ticks;
        uint256 remainingTicks;
        uint256 startedTime;
        uint256 endedTime;
        uint256 lastTriggerTime;
    }

    function factory() external view returns (address);

    function getTokenId(
        address token0,
        address token1,
        uint8 frequency,
        uint256 planIndex
    ) external view returns (uint256);

    function plansOf(address) external view returns (uint256[] memory);

    function getPlan(uint256 tokenId)
        external
        view
        returns (Plan memory plan, PlanStatistics memory statistics);

    function createPoolIfNecessary(PoolAddress.PoolInfo calldata poolInfo)
        external
        payable
        returns (address pool);

    struct MintParams {
        address token0;
        address token1;
        uint8 frequency;
        address investor;
        address owner;
        uint256 tickAmount;
        uint256 periods;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint256 planIndex);

    function extend(uint256 id, uint256 periods) external payable;

    function burn(uint256 id)
        external
        returns (uint256 received0, uint256 received1);

    function withdraw(uint256 id) external returns (uint256 received1);

    function withdrawIn(uint256 id, uint256 periods)
        external
        returns (uint256 received1);

    function claimReward(uint256 id)
        external
        returns (
            address token,
            uint256 unclaimedAmount,
            uint256 claimedAmount
        );
}
