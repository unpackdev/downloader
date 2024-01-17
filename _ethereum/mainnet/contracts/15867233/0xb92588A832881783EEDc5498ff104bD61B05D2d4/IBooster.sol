pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function poolInfo(uint256 _index) external view returns (PoolInfo memory);

    function poolLength() external view returns (uint256);
}
