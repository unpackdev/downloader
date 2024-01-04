pragma solidity >=0.6.6;

interface IDInterest {
    function deposit(uint256 amount, uint256 maturationTimestamp) external;
    function depositsLength() external view returns (uint256);
    function withdraw(uint256 depositID, uint256 fundingID) external;
    function earlyWithdraw(uint256 depositID, uint256 fundingID) external;
    function mphMinter() external view returns (address);
}
