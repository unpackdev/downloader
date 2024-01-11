//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ILLC.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./LLCSalesData.sol";

contract LLCMinter is Ownable, Pausable, ReentrancyGuard, LLCSalesData {
    /// @dev LLC NFT Contract address
    address public immutable LLC_ADDRESS;

    constructor(address _llc) {
        require(_llc != address(0), "Invalid LLC Contract Address");

        LLC_ADDRESS = _llc;
        _pause();
    }

    // ----------------- EXTERNAL -----------------

    /// @dev Set Minting Round configuration
    function setRoundConfiguration(LLCMintingRound calldata round) external onlyOwner {
        require(round.startTime > block.timestamp, "Invalid round start time");
        require(round.endTime > round.startTime, "Invalid round end time");
        require(round.merkleRoot.length > 0, "Invalid merkle root");
        require(round.participants > 0, "Invalid number of participants");

        rounds.push(round);

        emit NewSaleRound(round.mintingFee, round.startTime, round.endTime, round.merkleRoot);
    }

    /// @dev Pause activity
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause activity
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Withdraw funds from contract
    function withdraw(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    /// @dev Mint LLC
    function mint(
        bytes32[] memory _proof,
        bytes32 leaf,
        uint256 _roundId
    ) external payable nonReentrant whenNotPaused onlyOngoingRound(_roundId) {
        require(!participants[_roundId][_msgSender()], "Already participated");

        LLCMintingRound memory round = rounds[_roundId];
        require(MerkleProof.verify(_proof, round.merkleRoot, leaf), "Sender not on whitelist");
        require(msg.value == round.mintingFee, "Invalid Price");

        // Mint LLC NFT
        getLLC().mint(_msgSender(), 1);

        // Set participant
        participants[_roundId][_msgSender()] = true;

        // Update sale round status
        LLCMintingRoundStatus storage status = roundStatus[_roundId];
        status.participants++;
        status.volume += msg.value;

        emit NewParticipant(_roundId, _msgSender());
    }

    // ----------------- VIEW -----------------

    /// @dev Get LLC Contract Address
    function getLLC() public view returns (ILLC) {
        return ILLC(LLC_ADDRESS);
    }

    /// @dev Get Next Round Id
    function getNextRoundId() public view returns (uint256) {
        return rounds.length;
    }

    // ----------------- MODIFIER -----------------

    modifier onlyOngoingRound(uint256 _roundId) {
        require(_roundId < getNextRoundId(), "Invalid roundId");

        LLCMintingRound memory round = rounds[_roundId];
        require(round.startTime <= block.timestamp, "Sale Round is not started yet");
        require(round.endTime >= block.timestamp, "Sale Round was ended");
        require(round.participants > roundStatus[_roundId].participants, "Sale was fulfilled");
        _;
    }
}
