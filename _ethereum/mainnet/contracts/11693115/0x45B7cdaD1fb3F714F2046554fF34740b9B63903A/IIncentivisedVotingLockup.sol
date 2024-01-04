pragma solidity 0.6.8;

import "./IERC20WithCheckpointing.sol";

interface IIncentivisedVotingLockup is IERC20WithCheckpointing {

    function getLastUserPoint(address _addr) external view returns(int128 bias, int128 slope, uint256 ts);
    function createLock(uint256 _value, uint256 _unlockTime) external;
    function withdraw() external;
    function increaseLockAmount(uint256 _value) external;
    function increaseLockLength(uint256 _unlockTime) external;
    function expireContract() external;
    
}