// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IWarped {
    error AlreadyClaimedAllRewards(address user);
    error InvalidProof();
    error NothingToClaim();
    error DistributionDidntYetStart(uint256 start, uint256 currentTimestamp);
    error AddressZero();
    error InvalidStart();
    error InvalidMerkleRoot();
    error AlreadyStarted(uint256 start);
    error DistributionIsntActive();
    error InsufficientAmount(uint256 required, uint256 sent);

    event Claimed(address indexed user, uint256 indexed amount);
    event SaleActivated(uint256 start, uint256 firstCliff, uint256 secondCliff);

    struct UserInfo {
        uint256 amountClaimed;
        bool claimedAll;
        uint256 firstClaimTimestamp;
        uint256 secondClaimTimestamp;
        uint256 thirdClaimTimestamp;
    }

    enum VestingPeriod {
        DidntStart, // Distribution didn't yet start
        First, // 0 - 6. First 6 weeks where the user can claim 40%
        Second, // 6 - 12. Second 6 weeks where you can claim 30%
        Third // 12 -> Third 6 weeks where you can claim another 30% so all remaining tokens
    }

    function claimedAmount(address _user) external view returns (uint256);

    function claimedAll(address _user) external view returns (bool);

    function accountInfo(address) external view returns (UserInfo memory);

    function getPeriod() external view returns (VestingPeriod);

    function claim(uint256, bytes32[] calldata) external;
}
