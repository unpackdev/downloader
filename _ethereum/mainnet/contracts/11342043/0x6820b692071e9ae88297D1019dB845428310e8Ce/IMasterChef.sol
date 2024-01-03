pragma solidity 0.7.0;

interface IMasterChef {
    function deposit(uint256, uint256) external;
    function withdraw(uint256, uint256) external;
    function userInfo(uint256, address) external view returns (uint256, uint256);
    function poolInfo(uint256) external view returns (address, uint256, uint256, uint256);
    function massUpdatePools() external;
    function pendingSushi(uint256, address) external view returns (uint256);
    function pendingPickle(uint256, address) external view returns (uint256);
}
