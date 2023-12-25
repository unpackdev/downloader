pragma solidity ^0.7.4;

interface IPooledStaking {
    event UnstakeRequested(
        address indexed contractAddress,
        address indexed staker,
        uint256 amount,
        uint256 unstakeAt
    );

    function contractStake(address contractAddress) external view returns (uint256);

    function depositAndStake(
        uint256 amount,
        address[] calldata _contracts,
        uint256[] calldata _stakes
    ) external;

    function hasPendingActions() external view returns (bool);

    function hasPendingBurns() external view returns (bool);

    function hasPendingUnstakeRequests() external view returns (bool);

    function hasPendingRewards() external view returns (bool);

    function lastUnstakeRequestId() external view returns (uint256);

    function pushRewards(address[] calldata contractAddresses) external;

    function processPendingActions(uint256 maxIterations) external returns (bool finished);

    function stakerReward(address staker) external view returns (uint256);

    function stakerContractsArray(address staker) external view returns (address[] memory);

    function stakerContractStake(address staker, address contractAddress)
        external
        view
        returns (uint256);

    function stakerDeposit(address staker) external view returns (uint256);

    function requestUnstake(
        address[] calldata _contracts,
        uint256[] calldata _amounts,
        uint256 _insertAfter
    ) external;

    function withdraw(uint256 amount) external;

    function unstakeRequests(uint256 requestId)
        external
        view
        returns (
            uint256 amount,
            uint256 unstakeAt,
            address contractAddress,
            address stakerAddress,
            uint256 next
        );

    function stakerContractPendingUnstakeTotal(address staker, address contractAddress)
        external
        view
        returns (uint256);

    function withdrawReward(address stakerAddress) external;

    function stakerMaxWithdrawable(address stakerAddress) external view returns (uint256);

    function UNSTAKE_LOCK_TIME() external view returns (uint256);

    function MIN_STAKE() external view returns (uint256);
}
