pragma solidity 0.6.6;

interface ISafetyLocker {
    function verifyTransfer(address source, address dest) external;
    function verifyUserAddress(address user, uint256 amount) external;
    function IsSafetyLocker() external pure returns(bool);
}