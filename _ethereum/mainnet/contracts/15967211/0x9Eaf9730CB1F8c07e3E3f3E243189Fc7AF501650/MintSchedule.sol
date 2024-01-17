// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

contract MintSchedule is Ownable {
    // In epoch
    uint256 public preMintStart;
    uint256 public preMintEnd;
    uint256 public publicMintStart;
    uint256 public publicMintEnd;

    constructor() {}

    function setPreMintTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(
            _endTime >= _startTime,
            "Pre-Mint end time cannot be later than start time."
        );
        preMintStart = _startTime;
        preMintEnd = _endTime;
    }

    function isPreMintActivated() public view returns (bool) {
        return
            preMintStart > 0 &&
            preMintEnd > 0 &&
            block.timestamp >= preMintStart &&
            block.timestamp <= preMintEnd;
    }

    modifier isPreMintActive() {
        require(
            isPreMintActivated(),
            "Pre-Mint not activated."
        );
        _;
    }

    function setPublicMintTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(
            _endTime >= _startTime,
            "Public Mint end time cannot be later than start time."
        );
        publicMintStart = _startTime;
        publicMintEnd = _endTime;
    }

    function isPublicMintActivated() public view returns (bool) {
        return
            publicMintStart > 0 &&
            publicMintEnd > 0 &&
            block.timestamp >= publicMintStart &&
            block.timestamp <= publicMintEnd;
    }

    modifier isPublicMintActive() {
        require(
            isPublicMintActivated(),
            "Public Mint not activated."
        );
        _;
    }
}