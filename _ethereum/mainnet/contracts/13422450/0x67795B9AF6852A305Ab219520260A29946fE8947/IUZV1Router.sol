// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./IUZV1RewardPool.sol";
import "./SharedDataTypes.sol";

interface IUZV1Router {
    /* view functions */
    function getAllUserRewards(address _user)
        external
        view
        returns (address[] memory _pools, uint256[] memory _rewards);

    function getAllPools() external view returns (address[] memory);

    function getAllTokens()
        external
        view
        returns (
            address[] memory tokenList,
            uint256[] memory tokenTVLs,
            uint256[] memory weights,
            uint256 combinedWeight
        );

    function getAllTokens(uint256 _blocknumber)
        external
        view
        returns (
            address[] memory tokenList,
            uint256[] memory tokenTVLs,
            uint256[] memory weights,
            uint256 combinedWeight
        );

    function getTVLs() external view returns (uint256[] memory _tokenTVLs);

    function getTVLs(uint256 _blocknumber)
        external
        view
        returns (uint256[] memory _tokenTVLs);

    function getUserTVLShare(address _user, uint256 _precision)
        external
        view
        returns (uint256[] memory);

    function getStakingUserData(address _user)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        );

    function getTokenWeights()
        external
        view
        returns (uint256[] memory weights, uint256 combinedWeight);

    function getUserStakes(address _user)
        external
        view
        returns (uint256[] memory);

    function getUserStakes(address _user, uint256 _blocknumber)
        external
        view
        returns (uint256[] memory);

    function getUserStakesSnapshots(
        address _user,
        address _token,
        uint256 _startBlock,
        uint256 _endBlock
    )
        external
        view
        returns (SharedDataTypes.StakeSnapshot[] memory startBlocks);

    /* pool view functions */

    function canReceiveRewards(address _pool) external view returns (bool);

    function isPoolNative(address _pool) external view returns (bool);

    function getPoolState(address _pool)
        external
        view
        returns (SharedDataTypes.PoolState);

    function getPoolType(address _pool) external view returns (uint8);

    function getPoolInfo(address _pool)
        external
        view
        returns (SharedDataTypes.PoolData memory);

    function getTimeWindows(address _pool)
        external
        view
        returns (uint256[] memory);

    function getPoolUserReceiverAddress(address _pool, address _user)
        external
        view
        returns (string memory receiverAddress);

    function getPoolUserInfo(address _pool, address _user)
        external
        view
        returns (SharedDataTypes.FlatPoolStakerUser memory);

    function getTotalPriceForPurchaseableTokens(address _pool, address _user)
        external
        view
        returns (uint256);

    /* mutating functions */
    function claimAllRewards() external;

    function claimReward(address _pool) external returns (bool);

    function claimRewardsFor(IUZV1RewardPool[] calldata pools) external;

    function payRewardAndSetNativeAddressForPool(
        address _pool,
        uint256 _amount,
        string calldata _receiver
    ) external;

    function payRewardPool(address _pool, uint256 _amount) external;

    function createNewPool(
        uint256 totalRewards,
        uint256 startBlock,
        uint256 endBlock,
        address token,
        uint8 poolType,
        string memory name,
        string memory blockchain,
        string memory cAddress
    ) external returns (address);

    function setNativeAddressForPool(address _pool, string calldata _receiver)
        external;

    /* control functions */
    function setFactory(address _factory) external;

    function setStaking(address _staking) external;

    function emergencyWithdrawTokenFromRouter(address _token, uint256 _amount)
        external;
}
