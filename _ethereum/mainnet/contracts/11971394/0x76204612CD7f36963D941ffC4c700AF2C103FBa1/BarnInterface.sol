pragma solidity >=0.6.0 <0.7.0;

import "./IERC20Upgradeable.sol";

interface BarnInterface {
    function balanceOf(address _address) external view returns (uint256);
    
    function deposit(uint256 _amount) external;

    function depositAndLock(uint256 _amount, uint256 _timestamp) external;
    
    function withdraw(uint256 _amount) external;

    function userLockedUntil(address _user) external view returns (uint256);

    function bondStaked() external view returns (uint256);
}