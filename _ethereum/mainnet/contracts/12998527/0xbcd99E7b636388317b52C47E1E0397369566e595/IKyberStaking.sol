pragma solidity 0.6.2;

interface IKyberStaking {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getLatestStakeBalance(address staker) external view returns(uint);
}
