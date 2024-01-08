// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./SharedDataTypes.sol";

interface IUZV1RewardPool {
    /* mutating functions */
    function claimRewards(address _user) external;

    function factory() external returns (address);

    function setFactory(address) external;

    function transferOwnership(address _newOwner) external;

    function pay(address _user, uint256 _amount)
        external
        returns (uint256 refund);

    /* view functions */
    // pool specific
    function canReceiveRewards() external view returns (bool);

    function isPoolActive() external view returns (bool);

    function isPayable() external view returns (bool);

    function isNative() external view returns (bool);

    function getPoolState() external view returns (SharedDataTypes.PoolState);

    function getUserPoolStake(address _user)
        external
        view
        returns (SharedDataTypes.PoolStakerUser memory);

    function getUserPoolState()
        external
        view
        returns (SharedDataTypes.UserPoolState);

    function getPoolType() external view returns (uint8);

    function getPoolInfo()
        external
        view
        returns (SharedDataTypes.PoolData memory);

    function getAmountOfOpenRewards() external view returns (uint256);

    function getStartBlock() external view returns (uint256);

    function getEndBlock() external view returns (uint256);

    function getTimeWindows() external view returns (uint256[] memory);

    function getUserReceiverAddress(address user)
        external
        view
        returns (string memory receiverAddress);

    // user specific
    function getPendingRewards(address _user)
        external
        view
        returns (uint256 reward);

    function getUserInfo(address _user)
        external
        view
        returns (SharedDataTypes.FlatPoolStakerUser memory);

    function setNativeAddress(address _user, string calldata _receiver)
        external;

    function initialize(address _router, address _accessToken) external;

    function setPoolData(SharedDataTypes.PoolInputData calldata _inputData)
        external;

    function withdrawTokens(address _tokenAddress, uint256 _amount) external;

    function setStakingWindow(uint256 _startBlock, uint256 _endBlock) external;
}
