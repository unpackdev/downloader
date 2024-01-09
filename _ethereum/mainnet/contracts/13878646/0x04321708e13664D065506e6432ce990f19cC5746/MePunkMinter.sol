// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface Punk {
    function mint(address receiver) external returns (uint256 mintedTokenId);
}

contract MePunkMinter is Ownable, ReentrancyGuard {
    Punk public constant mePunk =
        Punk(0x3183cC9eB6DBde10866C4886389c0150fFa7F35d);
    uint256 public remainingMintCount;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public maxNFTPurchase;
    uint256 public price;

    constructor() {
        maxNFTPurchase = 3;
        price = 0.08 ether;
        remainingMintCount = 100;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxNFTPurchase(uint256 _maxNFTPurchase) external onlyOwner {
        maxNFTPurchase = _maxNFTPurchase;
    }

    function setMintTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(
            _startTime < _endTime,
            "startTime has to be smaller than endTime"
        );
        startTime = _startTime;
        endTime = _endTime;
    }

    function setRemainingMintCount(uint256 _remainingMintCount)
        external
        onlyOwner
    {
        remainingMintCount = _remainingMintCount;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mintMePunk(uint256 numberOfTokens) external payable nonReentrant {
        require(tx.origin == msg.sender, "smart contract not allowed to mint");
        require(startTime != 0, "startTime not set");
        require(endTime != 0, "endTime not set");
        require(block.timestamp > startTime, "not yet started");
        require(block.timestamp < endTime, "has finished");
        require(
            numberOfTokens > 0,
            "numberoOfTokens can not be less than or equal to 0"
        );
        require(
            numberOfTokens <= maxNFTPurchase,
            "numberOfTokens exceeds purchase limit per tx"
        );
        require(
            numberOfTokens <= remainingMintCount,
            "numberOfTokens would exceed remaining mint count for this batch"
        );
        require(
            price * numberOfTokens == msg.value,
            "Sent ether value is incorrect"
        );
        remainingMintCount -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            mePunk.mint(msg.sender);
        }
    }
}
