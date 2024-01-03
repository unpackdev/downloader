pragma solidity ^0.6.6;

interface IGFarming {
    function changeMaxPoolsCount(uint256) external;

    function changeRewardsPerBlock(uint256) external;

    function changeLockForever(bool) external;

    function maxPools() external view returns (uint256);

    function rewardsPerBlock() external view returns (uint256);

    function lockForever() external view returns (bool);
}
