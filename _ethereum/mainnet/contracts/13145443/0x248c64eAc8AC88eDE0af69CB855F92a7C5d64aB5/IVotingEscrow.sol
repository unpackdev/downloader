pragma solidity ^0.6.0;

interface IVotingEscrow {
    function getLastUserSlope(address addr) external view returns (int128);

    function lockedEnd(address addr) external view returns (uint256);

    function userPointEpoch(address addr) external view returns (uint256);

    function userPointHistoryTs(address addr, uint256 epoch)
        external
        view
        returns (uint256);

    function balanceOfAt(address addr, uint256 _block)
        external
        view
        returns (uint256);

    function lockStarts(address addr) external view returns (uint256);

    function MAXTIME() external pure returns (uint256);
}
