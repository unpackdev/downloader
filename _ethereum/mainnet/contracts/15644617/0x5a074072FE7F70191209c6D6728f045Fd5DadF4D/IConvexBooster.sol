pragma solidity >=0.5.0 <0.9.0;

interface IConvexBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }
    function poolInfo(uint256 _pid) view external returns (PoolInfo memory);

    function crv() external view returns (address);

    function minter() external view returns (address);

    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);

    function depositAll(uint256 _pid, bool _stake) external returns(bool);
}