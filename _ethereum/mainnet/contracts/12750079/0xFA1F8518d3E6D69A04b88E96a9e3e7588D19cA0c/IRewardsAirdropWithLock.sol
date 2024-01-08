// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IRewardsAirdropWithLock {
    event Claimed(uint256 roundInd, uint256 merkleInd, address account, uint256 claimedAmount, uint256 amount);
    event UpdatedPenaltyReceiver(address old, address _new);
    event UpdatedRoundStatus(uint256 roundInd, bool oldDisabled, bool _newDisabled);
    event AddedAirdrop(uint256 roundInd, address token, uint256 total);

    struct AirdropRound {
        address token;
        bytes32 merkleRoot;
        bool disabled;
        uint256 startTime;
        uint256 lockWindow;
        uint256 lockRate;
        uint256 total;
        uint256 totalClaimed;
    }

    function penaltyReceiver() external view returns (address);
    function claimWindow() external view returns (uint256);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 _roundsIndex, uint256 index) external view returns (bool);

    // extra view
    function getAllAirdropRounds() external returns (AirdropRound[] memory);
    function getAirdropRounds(uint256 _startInd, uint256 _endInd) external returns (AirdropRound[] memory);
    function getAirdropRoundsLength() external returns (uint256);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(
        uint256 _roundsIndex,
        uint256 _merkleIndex,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    // Only owner
    function updatePaneltyReceiver(address _new) external;
    function addAirdrop(
        address _token,
        bytes32 _merkleRoot,
        uint256 _lockWindow,
        uint256 _lockRate,
        uint256 _total
    ) external returns (uint256);
    function updateRoundStatus(uint256 _roundInd, bool _disabled) external;
}